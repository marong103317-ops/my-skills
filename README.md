# my-skills

个人技能（Skills）收集仓库：所有自定义技能以文件夹形式放在 [skills/](skills/) 下，每个技能包含一个 `SKILL.md`。

## 技能目录

<!-- SKILLS-INDEX:START -->
| 技能 | 说明 |
| --- | --- |
| （暂无技能） | 将技能文件夹放入 skills/ 后重新运行脚本 |
<!-- SKILLS-INDEX:END -->

## 如何更新目录

每次新增或修改技能后，运行：

```bash
bash scripts/update_skill_index.sh
```

脚本会扫描 `skills/` 下的所有文件夹（读取其中 `SKILL.md` 的 name / description），并重新生成上方标记之间的目录表格，自动去重。
