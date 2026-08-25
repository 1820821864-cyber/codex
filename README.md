# Codex Short Drama Director

面向 Codex 的短剧创作技能仓库，参考 `my401367513-creator/deepseek` 的模块化思路重新设计，不依赖 DeepSeek Desktop 专属组件。云端仅保存可复用技能；所有项目数据仅保存在各自的本地项目目录。

## 结构

- `skills/short-drama-script-analysis`：剧本诊断与人物档案
- `skills/short-drama-assets`：人物/场景/道具/音频资产库
- `skills/short-drama-prompts`：AI 视频提示词
- `scripts/sync.ps1`：安全拉取、提交与推送

相关对话产生确认过的通用技能改进后，Codex 更新技能并执行同步脚本。同步只发生在技能相关文件实际变化时；项目内容永不进入仓库。冲突或网络失败会保留本地提交并停止，不会强推。

每次执行相关任务，Codex 都重新读取技能和本地项目目录中的项目记忆、档案与已有结论。新的要求若可能改变通用技能行为，会先询问用户是否要沉淀为技能更新；确认后才修改并同步仓库。
