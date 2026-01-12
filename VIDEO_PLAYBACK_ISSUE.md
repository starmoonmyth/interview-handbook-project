# App 端视频播放技术总结

## 问题背景
在 App 开发过程中，视频播放功能遇到了一些挑战，主要表现为视频无法播放、解码错误（`PIPELINE_ERROR_DECODE`）或 URL 解析错误。针对这些问题，我们进行了详细的排查和优化。

## 关键问题点

1.  **资源路径拦截 (AuthInterceptor)**
    *   **现象**: App 访问受保护的资源时，如果 Header 中携带了 Token，可能会触发后端的鉴权逻辑。
    *   **建议**: 访问静态资源（如视频、图片）时，建议不携带 Token，或者后端配置明确排除这些路径的鉴权。
    *   **现状**: 使用 ArkTS 的 `Web` 组件加载 URL 时，默认不会携带 App 层的 Token，符合建议。

2.  **IP 地址与 URL 拼接**
    *   **现象**: 在开发环境中，服务器地址配置为 `localhost` 时，模拟器或真机无法访问。或者 URL 拼接时出现双斜杠（`//`）或缺少斜杠。
    *   **优化**:
        *   确保 `NetworkConfig.BASE_URL` 配置为局域网 IP（如 `192.168.x.x`）。
        *   优化 `resolveUrl` 逻辑，智能处理 `BASE_URL` 尾部的斜杠和相对路径开头的斜杠，防止拼接错误。
        *   在 `VideoPlayPage` 中增加了对 `localhost/127.0.0.1` 的自动替换逻辑。

3.  **视频播放组件选择**
    *   **原生 `Video` 组件 vs `Web` 组件**:
        *   原生 `Video` 组件在处理某些编码格式或网络流时可能存在兼容性问题。
        *   `Web` 组件（基于系统 WebView 内核）通常具有更强的格式支持和网络容错能力。
    *   **Web 组件加载方式**:
        *   **注入 HTML (`loadData`)**: 之前尝试通过注入包含 `<video>` 标签的 HTML 来播放，但这可能引入跨域问题、Base URL 问题或复杂的交互问题。
        *   **直接加载 URL (`loadUrl`/`src`)**: **[推荐]** 直接将视频 URL 赋值给 `Web` 组件的 `src` 属性。这让浏览器内核直接接管视频播放，通常能提供最稳定、原生的播放体验。

4.  **网络安全配置**
    *   **HTTP 支持**: HarmonyOS 默认限制明文 HTTP 流量。
    *   **配置**: 需在 `module.json5` 中引用 `network_security_config`，并在配置文件中设置 `"cleartextTrafficPermitted": true` 以允许 HTTP 请求。

## 优化方案实施

在 `VideoPlayPage.ets` 中进行了以下修改：

1.  **优化 URL 解析**:
    ```typescript
    // 移除 BASE_URL 末尾的 'hm/' 和 '/'，确保干净的 Base URL
    const baseUrlRoot = NetworkConfig.BASE_URL.replace(/\/hm\/?$/, '').replace(/\/$/, '')
    // ...
    videoUrl = `${baseUrlRoot}/${cleanPath}`
    ```

2.  **简化播放逻辑**:
    移除复杂的 HTML 注入代码，直接使用：
    ```typescript
    Web({ src: this.url, controller: this.controller })
      .mixedMode(MixedMode.All) // 允许混合内容
      // ...
    ```

3.  **移除不必要的刷新**:
    移除了 `onPageShow` 中的 `this.controller.refresh()`，防止视频加载被中断或重复加载。

## 验证清单

- [x] 确保手机/模拟器和电脑在同一 WiFi 下。
- [x] 确保 `NetworkConfig.BASE_URL` 配置为电脑的局域网 IP。
- [x] 确保上传的视频文件确实存在于服务器对应目录下。
- [x] 确保 `module.json5` 配置了网络权限。
