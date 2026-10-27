# 乖离剑 Ea × Rising Legends 2 安装说明

整合包 = **Rising Legends 2**（RLCraft 2）+ **乖离剑**。装好以后，每次启动游戏都会自动更新乖离剑，不用再手动下载。

## 一、安装 Prism Launcher（只做一次）
1. 打开 https://prismlauncher.org ，点 Download → Windows → 下载安装程序，一路"下一步"装好。
2. 打开 Prism Launcher，右上角"账户" → 添加 Microsoft 账号，登录你的正版账号。
   第一次启动时如果问 Java，选"自动下载"即可。

## 二、导入整合包（只做一次）
1. 左上角"添加实例" → 左边选 **Modrinth** → 搜索 `Rising Legends 2` → 选版本 **1.2** → 确定，等它下载完。
2. 下载这个文件：https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar
3. 右键刚才的实例 → "文件夹"，打开后进入里面的 `minecraft` 文件夹（有的版本叫 `.minecraft`），把第 2 步下载的文件放进去。
4. 右键实例 → "编辑" → "设置" → "自定义命令"，勾上，在 **启动前命令** 里粘贴下面这一整行：

   ```
   "$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://raw.githubusercontent.com/zhengyutong002-ai/ea-modpack/main/pack.toml
   ```
5. 同一个"设置"页 → "Java" → 最大内存改成 **8192 MB**（模组很多，内存小会卡或崩）。
6. 点"启动"。第一次会弹出一个小窗口下载乖离剑，下完自动进游戏。以后每次启动都会自动检查更新。

## 三、一起联机（用 playit.gg，只有房主要装，朋友什么都不用装）
**房主第一次（只做一次）：**
1. 打开 https://playit.gg ，下载 Windows 版并安装，启动后按提示用浏览器登录（免费账号）。
2. 在 playit 网页里 "Add Tunnel" → 类型选 **Minecraft Java** → 本地端口填 **25565** → 创建。会得到一个固定地址（类似 `xxxx.joinmc.link`），以后一直用这个。

**每次联机：**
- **房主**：先开着 playit 程序 → 进单人世界 → Esc → "对局域网开放" → 端口填 **25565** → 开始。把上面的固定地址发给朋友。
- **朋友**：主菜单 → 多人游戏 → 添加服务器（或直接连接）→ 填房主的地址 → 加入。
- 房主关掉游戏或 playit 程序后，朋友就进不来了。

## 常见问题
- 启动时报"版本不匹配 / 缺少模组"：确认整合包版本是 Rising Legends 2 **1.2**，并且启动前命令那一行没有漏字。
- 大家的乖离剑版本必须一样：都重启一次游戏就会自动更新到最新。
- 开着光影（Iris）时乖离剑的部分特效（扭曲、碎裂）可能看不到，关掉光影即可。
