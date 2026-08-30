#Requires -Version 7.0

param(
  [string]$SkillsRoot = ''
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($SkillsRoot)) {
  $SkillsRoot = Join-Path $repoRoot 'skills'
}
$SkillsRoot = [System.IO.Path]::GetFullPath($SkillsRoot)
if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) {
  throw "Skills root not found: $SkillsRoot"
}

$codexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$validator = Join-Path $codexRoot 'skills\.system\skill-creator\scripts\quick_validate.py'
if (-not (Test-Path -LiteralPath $validator -PathType Leaf)) {
  throw "Skill validator not found: $validator"
}

$pythonCandidates = @(@(
  $env:CODEX_PYTHON,
  (Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe')
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Leaf) })
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCommand -and $pythonCommand.Source -notin $pythonCandidates) {
  $pythonCandidates += $pythonCommand.Source
}
if (-not $pythonCandidates) { throw 'No usable Python runtime found.' }
$python = $null
foreach ($candidate in $pythonCandidates) {
  try {
    & $candidate -X utf8 -c 'import sys; assert sys.version_info >= (3, 9)' *> $null
    if ($LASTEXITCODE -eq 0) { $python = $candidate; break }
  } catch { continue }
}
if (-not $python) { throw "No usable Python runtime among: $($pythonCandidates -join ', ')" }

$skillNames = @(
  'short-drama-director',
  'short-drama-script-analysis',
  'short-drama-story-writing',
  'short-drama-assets',
  'short-drama-prompts',
  'short-drama-image-design'
)
$expectedVersion = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw -Encoding utf8).Trim()

foreach ($name in $skillNames) {
  $skillDir = Join-Path $SkillsRoot $name
  $skillFile = Join-Path $skillDir 'SKILL.md'
  if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
    throw "Missing skill: $skillFile"
  }
  & $python -X utf8 $validator $skillDir
  if ($LASTEXITCODE -ne 0) { throw "Skill validation failed: $name" }

  $skillText = Get-Content -LiteralPath $skillFile -Raw -Encoding utf8
  $versionMatch = [regex]::Match($skillText, '(?m)^\s*version:\s*"([^"]+)"\s*$')
  if (-not $versionMatch.Success -or $versionMatch.Groups[1].Value -ne $expectedVersion) {
    throw "Version mismatch in $name; expected $expectedVersion"
  }
}

$markdownFiles = foreach ($name in $skillNames) {
  Get-ChildItem -LiteralPath (Join-Path $SkillsRoot $name) -Recurse -File -Filter '*.md'
}
foreach ($file in $markdownFiles) {
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding utf8
  foreach ($match in [regex]::Matches($text, '\[[^\]]+\]\(([^)]+)\)')) {
    $target = $match.Groups[1].Value.Split('#')[0]
    if ([string]::IsNullOrWhiteSpace($target) -or $target -match '^(https?:|mailto:|#)') { continue }
    if ([System.IO.Path]::IsPathRooted($target) -or $target.StartsWith('\\')) {
      throw "Absolute or UNC links are not allowed in $($file.FullName): $target"
    }
    $resolved = [System.IO.Path]::GetFullPath((Join-Path $file.DirectoryName $target))
    $skillsPrefix = $SkillsRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($skillsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Relative link escapes the skills root in $($file.FullName): $target"
    }
    if (-not (Test-Path -LiteralPath $resolved)) {
      throw "Broken relative link in $($file.FullName): $target"
    }
  }
}

$promptRoot = Join-Path $SkillsRoot 'short-drama-prompts'
$requiredPromptFiles = @(
  'references\modules\source-context.md',
  'references\modules\audio-timeline.md',
  'references\modules\assets-references.md',
  'references\modules\performance.md',
  'references\modules\shot-continuity.md',
  'references\modules\timing-segmentation.md',
  'references\modules\project-style.md',
  'references\modules\output-format.md',
  'references\templates\director-compact.md',
  'references\adapters\seedance.md',
  'references\libraries\camera.md',
  'references\libraries\shot-scale-atmosphere.md',
  'references\libraries\axis-line.md',
  'references\libraries\lighting.md',
  'references\libraries\ritual-vfx.md',
  'references\quality\delivery-checklist.md',
  'references\maintenance\rule-index.md'
)
foreach ($relative in $requiredPromptFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $promptRoot $relative) -PathType Leaf)) {
    throw "Missing prompt module: $relative"
  }
}

function Assert-Contains([string]$RelativePath, [string]$Expected) {
  $path = Join-Path $SkillsRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing invariant file: $RelativePath" }
  $text = Get-Content -LiteralPath $path -Raw -Encoding utf8
  if (-not $text.Contains($Expected)) { throw "Confirmed invariant missing in $RelativePath`: $Expected" }
}

function Assert-NotContains([string]$RelativePath, [string]$Forbidden) {
  $path = Join-Path $SkillsRoot $RelativePath
  $text = Get-Content -LiteralPath $path -Raw -Encoding utf8
  if ($text.Contains($Forbidden)) { throw "Regressed rule detected in $RelativePath`: $Forbidden" }
}

$directorSkill = 'short-drama-director\SKILL.md'
$promptSkill = 'short-drama-prompts\SKILL.md'
$ruleIndex = 'short-drama-prompts\references\maintenance\rule-index.md'
$assetsSkill = 'short-drama-assets\SKILL.md'
$assetsModule = 'short-drama-prompts\references\modules\assets-references.md'
$audioModule = 'short-drama-prompts\references\modules\audio-timeline.md'
$timingModule = 'short-drama-prompts\references\modules\timing-segmentation.md'
$shotModule = 'short-drama-prompts\references\modules\shot-continuity.md'
$styleModule = 'short-drama-prompts\references\modules\project-style.md'
$outputModule = 'short-drama-prompts\references\modules\output-format.md'
$template = 'short-drama-prompts\references\templates\director-compact.md'
$checklist = 'short-drama-prompts\references\quality\delivery-checklist.md'

foreach ($name in $skillNames) {
  Assert-Contains "$name\SKILL.md" '00-当前状态.md'
  Assert-Contains "$name\SKILL.md" '执行任务时称呼用户为“老大”，自称“小小鱼”。'
}
$agentsText = Get-Content -LiteralPath (Join-Path $repoRoot 'AGENTS.md') -Raw -Encoding utf8
if (-not $agentsText.Contains('address the user as “老大” and refer to yourself as “小小鱼”')) {
  throw 'Repository interaction naming rule is missing or inconsistent.'
}
Assert-Contains $directorSkill '执行清单'
Assert-Contains $directorSkill '相对链接只是路由入口，不等于已经完成调用'
Assert-Contains $directorSkill 'short-drama-image-design'
Assert-Contains $promptSkill '递归补齐“必需依赖”'
Assert-Contains $promptSkill '创意母版'
Assert-Contains $promptSkill '标题、场号和制作说明不得误判为成片旁白'
Assert-NotContains $promptSkill '不进行生成稳定性评级'
Assert-Contains $ruleIndex '运行期依赖闭包'
Assert-Contains $ruleIndex 'libraries/shot-scale-atmosphere.md'
Assert-Contains $ruleIndex 'libraries/axis-line.md'
Assert-Contains 'short-drama-prompts\references\libraries\shot-scale-atmosphere.md' '景别跳级与情绪量级'
Assert-Contains 'short-drama-prompts\references\libraries\shot-scale-atmosphere.md' '场景化景别组织'
Assert-Contains 'short-drama-prompts\references\libraries\axis-line.md' '三类核心轴线'
Assert-Contains 'short-drama-prompts\references\libraries\axis-line.md' '合法越轴方法'
Assert-Contains $timingModule '逐镜四层审查'
Assert-Contains $timingModule '其他工具按适配器'
Assert-Contains $audioModule '核心声音焦点可随景别改变'
Assert-Contains $audioModule '项目未确认音乐方案'
Assert-Contains $styleModule 'STY-04 剪辑方式'
Assert-Contains 'short-drama-prompts\references\modules\source-context.md' '剧本文本分类'
Assert-Contains $shotModule 'CAM-FRAME 实际位置与入画边界'
Assert-Contains $shotModule 'CAM-POSE 人物姿态与机位高度'
Assert-Contains $shotModule 'CAM-PROP 道具状态与交接'
Assert-Contains $shotModule '下一镜从<继承的主体／动作／视线／方向／构图重心／声音锚点>承接'
Assert-Contains $assetsModule 'AST-SCENE 原有场景资产复用'
Assert-Contains $assetsModule 'AST-STATE 项目身体与形态状态'
Assert-Contains $assetsModule 'AST-REF 最小必要参考集合'
Assert-Contains $assetsModule '不设置跨平台固定上限'
Assert-Contains $assetsSkill '职责重叠的普通状态图'
Assert-Contains $assetsSkill '待绑定参考'
Assert-Contains $assetsSkill '不得标为可投产'
Assert-Contains $assetsModule '确认文字生成'
Assert-Contains $assetsModule '未解析占位符'
Assert-Contains $outputModule '制作参考层'
Assert-Contains $outputModule '视频模型复制层'
Assert-Contains $outputModule '未解析占位符'
Assert-Contains $template '【第<X>集统一词头·严格锁定】'
Assert-Contains $template '本段执行约束：'
Assert-Contains $template '【镜头一｜时长<X.X>秒】'
Assert-Contains $checklist '执行与依据清单'
Assert-Contains $checklist '<实际状态>'

$checkText = Get-Content -LiteralPath (Join-Path $SkillsRoot $checklist) -Raw -Encoding utf8
if ($checkText -match '(?m)^\d+\..*：通过\s*$') {
  throw 'Delivery checklist must not prefill result rows as passed.'
}

$readmeText = Get-Content -LiteralPath (Join-Path $repoRoot 'README.md') -Raw -Encoding utf8
if (-not $readmeText.Contains("当前维护版本：``$expectedVersion``")) {
  throw "README current version does not match VERSION: $expectedVersion"
}

Write-Host "[validate] Skills, versions, links, dependency routing, 3.3 invariants, and installed-layout compatibility passed: $SkillsRoot"
