#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from inspect import cleandoc

class OSThemesCSS:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to unify the HTML styles for preparation of App design on different OS                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Read-only properties.                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |This section lists all the read-only properties of the class.                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |       Property Name         |                             Value Examples and Property Description                         #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | presets                     | The full collection of available presets defined in this class                              #
#   |   |   | Windows                     | The set of styles resembling Windows OS starting from root to some basic classes            #
#   |   |   | MacOS                       | The set of styles resembling Mac OS starting from root to some basic classes                #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260622        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inspect                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #090. Helper method to expose the available choices in this class
    @classmethod
    @property
    def presets(cls):
        mem = {
            attr
            for attr in dir(cls)
            if not attr.startswith('_')
            and not attr.endswith('_')
            and attr != 'presets'
        }
        return(mem)

    #100. Style set for Windows
    Windows : str = cleandoc('''
        /* =========================================
           1. 定义 CSS 变量 (Design Tokens)
           ========================================= */
        :root {
          /* --- 浅色模式 (Light Mode) 默认值 --- */

          /* 背景色：模拟 Mica 材质的基础底色 */
          --bg-primary: #f3f3f3;
          /* 表面/卡片背景：纯白或极浅灰，用于浮层 */
          --bg-surface: #ffffff;

          /* 文本颜色 */
          --font-family: 'Segoe UI Variable', 'Segoe UI', sans-serif; /* Windows 11 首选字体 */
          --font-m: 14px;
          --font-s: 12px;
          --font-xs: 10px;
          --text-primary: #1a1a1a;
          --text-secondary: #5d5d5d;
          /* rgba2rgb(--text-primary, alpha_in = 0.1, color_bg = --bg-primary) */
          --text-disabled: #DDDDDD;

          /* 边框颜色：细微的分隔线 */
          --border-color: #e5e5e5;
          --border-focus: #0067c0; /* Windows 11 默认强调蓝 */

          /* 强调色 (Accent Color)Windows 11 默认蓝色 */
          --accent-color: #0067c0;
          --accent-hover: #005a9e;
          --accent-text: #ffffff;

          /* 悬停效果背景 */
          --hover-bg: rgba(0, 0, 0, 0.04);

          /* 按钮由快捷键触发时的脉冲特效 */
          --anim-transition: 0.2s cubic-bezier(0.4, 0, 0.2, 1);
          --btn-pulse-bgn: rgba(0, 103, 192, 0.7);
          --btn-pulse-end: rgba(0, 103, 192, 0);

          /* 阴影：模拟层级深度 (Elevation) */
          --shadow-depth-4: 0 2px 4px rgba(0, 0, 0, 0.04), 0 4px 8px rgba(0, 0, 0, 0.04);
          --shadow-depth-8: 0 4px 8px rgba(0, 0, 0, 0.08), 0 8px 16px rgba(0, 0, 0, 0.08);

          /* Windows 11 标准圆角 */
          --radius-sm: 4px;
          --radius-md: 8px;
          --radius-lg: 12px;

          /* 已选区域 */
          --selection-bg: rgba(0, 103, 192, 0.1);
          --selection-border: #0067c0;

          /* 下拉菜单 */
          --dropdown-border: #d1d1d1;
          --dropdown-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
          --dropdown-item-hover: #f3f3f3;
          --dropdown-arrow-bg: rgba(0, 103, 192, 0.06);
          --dropdown-arrow-bg-active: rgba(0, 103, 192, 0.08);
          /* rgba2rgb(--text-secondary, alpha_in = 0.2, color_bg = --bg-primary) */
          --dropdown-group-label-bg: #D5D5D5;

          /* Explorer中按钮样式 */
          --explorer-btn-height : 28px;
          --explorer-margin-adj : 0;

          /* Explorer中分类显示详细信息时的分隔条 */
          /* 用 --text-primary 加透明度 */
          --group-sep-bg: rgba(26, 26, 26, 0.15);

          /* Explorer 底部状态栏 */
          --explorer-info-bg: rgba(26, 26, 26, 0.05);

          /* Tooltip 专属 */
          /* rgba2rgb(--text-primary, alpha_in = 0.08, color_bg = --bg-primary) */
          --tooltip-bg-grad: #E1E1E1;
        }

        /* --- 深色模式 (Dark Mode) 覆盖值 --- */
        @media (prefers-color-scheme: dark) {
          :root {
            /* 背景色：深灰，非纯黑，符合 Fluent Dark 规范 */
            --bg-primary: #202020;
            /* 表面/卡片背景：比背景稍亮 */
            --bg-surface: #2c2c2c;

            /* 文本颜色 */
            --text-primary: #ffffff;
            --text-secondary: #d0d0d0;
            /* rgba2rgb(--text-primary, alpha_in = 0.2, color_bg = --bg-primary) */
            --text-disabled: #363636;

            /* 边框颜色：在深色背景下更明显的分隔线 */
            --border-color: #3d3d3d;
            --border-focus: #4cc2ff; /* 深色模式下更亮的强调色 */

            /* 强调色 */
            --accent-color: #4cc2ff;
            --accent-hover: #3ab0ee;
            --accent-text: #000000; /* 深色强调色配黑色文字以保证对比度 */

            /* 悬停效果背景：白色半透明 */
            --hover-bg: rgba(255, 255, 255, 0.06);

            /* 按钮由快捷键触发时的脉冲特效 */
            --btn-pulse-bgn: rgba(76, 194, 255, 0.7);
            --btn-pulse-end: rgba(76, 194, 255, 0);

            /* 阴影：深色模式下阴影更柔和或不可见，主要靠亮度区分层级 */
            --shadow-depth-4: 0 2px 4px rgba(0, 0, 0, 0.2);
            --shadow-depth-8: 0 4px 8px rgba(0, 0, 0, 0.4);

            /* 已选区域 */
            --selection-bg: rgba(76, 194, 255, 0.15);
            --selection-border: #4cc2ff;

            /* 下拉菜单 */
            --dropdown-border: #3d3d3d;
            --dropdown-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
            --dropdown-item-hover: #383838;
            --dropdown-arrow-bg: rgba(76, 194, 255, 0.08);
            --dropdown-arrow-bg-active: rgba(76, 194, 255, 0.1);
            /* rgba2rgb(--text-secondary, alpha_in = 0.2, color_bg = --bg-primary) */
            --dropdown-group-label-bg: #434343;

            /* Explorer中分类显示详细信息时的分隔条 */
            /* 用 --text-primary 加透明度 */
            --group-sep-bg: rgba(255, 255, 255, 0.15);

            /* Explorer 底部状态栏 */
            --explorer-info-bg: rgba(255, 255, 255, 0.01);

            /* Tooltip 专属 */
            /* rgba2rgb(--text-primary, alpha_in = 0.08, color_bg = --bg-primary) */
            --tooltip-bg-grad: #313131;
            --tooltip-border: #3d3d3d;
          }
        }

        /* =========================================
           2. 基础全局样式
           ========================================= */
        body {
          background-color: var(--bg-primary);
          color: var(--text-primary);
          font-family: var(--font-family);
          margin: 0;
          padding: 24px;
          line-height: 1.5;
          transition: background-color 0.3s ease, color 0.3s ease;
        }

        /* =========================================
           3. Box 样式 (卡片/容器)
           模拟 Windows 11 的 Surface 层级
           ========================================= */
        .currOS-box {
          background-color: var(--bg-surface);
          border: 1px solid var(--border-color);
          border-radius: var(--radius-lg);
          padding: 24px;
          margin-bottom: 20px;
          box-shadow: var(--shadow-depth-4);
          transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
        }

        /* Box 悬停效果：轻微浮起 */
        .currOS-box:hover {
          box-shadow: var(--shadow-depth-8);
          transform: translateY(-2px);
          border-color: var(--border-focus); /* 可选：悬停时边框变强调色 */
        }

        /* =========================================
           4. 按钮样式 (Primary & Standard)
           遵循 Fluent Button 规范
           ========================================= */
        .currOS-btn {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: max-content;
          height: 36px; /* 标准高度 */
          padding: 0 16px;
          margin: 4px;

          background-color: var(--accent-color);
          color: var(--accent-text);

          border: 1px solid transparent; /* 预留边框位置防止抖动 */
          border-radius: var(--radius-sm);

          font-size: var(--font-m);
          font-weight: 600;
          cursor: pointer;

          /* 关键：过渡效果只应用于需要变化的属性 */
          transition: var(--anim-transition);
        }

        /* 按钮悬停 */
        .currOS-btn:hover {
          background-color: var(--accent-hover);
          color: var(--accent-text);
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        /* 按钮点击/激活 */
        .currOS-btn:active {
          transform: scale(0.98); /* 轻微缩放反馈 */
          opacity: 0.9;
        }

        /* 焦点状态：无障碍访问关键 */
        .currOS-btn:focus {
          outline: none;
        }
        .currOS-btn:focus-visible {
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          outline: 2px solid var(--border-focus);
          outline-offset: 2px;
        }

        .currOS-btn.key-triggered {
          animation: btnClickPulse 0.45s ease-out;
          animation-fill-mode: none; /* 确保动画结束后不保持最终状态 */
        }
        .currOS-btn.key-triggered.clicked {
          transform: scale(0.98);
        }

        /* =========================================
           5. 次要按钮样式 (Secondary/Outline)
           ========================================= */
        .currOS-btn-secondary {
          background-color: var(--bg-surface);
          color: var(--text-primary);
          border: 1px solid var(--border-color);
        }

        .currOS-btn-secondary:hover {
          background-color: var(--hover-bg);
          border-color: var(--text-secondary);
          color: var(--text-primary);
        }

        .currOS-btn-secondary.key-triggered {
          animation: btnClickPulse 0.45s ease-out;
          animation-fill-mode: none;
        }
        .currOS-btn-secondary.key-triggered.clicked {
          transform: scale(0.98);
        }

        /* =========================================
           Explorer中按钮样式
           ========================================= */
        .currOS-btn-explorer {
          background-color: var(--bg-primary);
          color: var(--text-secondary);
          border: none;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          height: var(--explorer-btn-height);
          padding: 0 4px;
          margin: 0;
          font-size: var(--font-m);
          font-family: var(--font-family);
          font-weight: 500;
          cursor: pointer;

          /* 关键：过渡效果只应用于需要变化的属性 */
          transition: background-color 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
        }

        /* 按钮悬停 */
        .currOS-btn-explorer:hover {
          background-color: var(--hover-bg);
          color: var(--text-secondary);
        }

        /* 按钮点击/激活 */
        .currOS-btn-explorer:active {
          transform: scale(0.98); /* 轻微缩放反馈 */
          opacity: 0.9;
        }

        /* 焦点状态：无障碍访问关键 */
        .currOS-btn-explorer:focus {
          outline: none;
        }
        .currOS-btn-explorer:focus-visible {
          outline: 2px solid var(--bg-surface);
          outline-offset: 2px;
        }

        .currOS-btn-explorer.key-triggered {
          animation: btnClickPulse 0.45s ease-out;
          animation-fill-mode: none;
        }
        .currOS-btn-explorer.key-triggered.clicked {
          transform: scale(0.98);
        }

        /* =========================================
           6. 输入框样式 (Input Fields)
           ========================================= */
        .currOS-input {
          width: 100%;
          padding: 8px 12px;
          margin: 8px 0;
          background-color: var(--bg-surface);
          color: var(--text-primary);
          caret-color: var(--text-primary);
          border: 1px solid var(--border-color);
          border-radius: var(--radius-sm);
          font-size: var(--font-m);
          box-sizing: border-box;
          transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }

        .currOS-input:hover {
          border-color: var(--text-secondary);
        }

        .currOS-input:focus {
          outline: none;
          background-color: var(--bg-primary);
          color: var(--text-primary);
          border-color: var(--border-focus);
          box-shadow: 0 0 0 2px rgba(0, 103, 192, 0.2); /* 聚焦光晕 */
        }

        /* 深色模式下聚焦光晕调整 */
        @media (prefers-color-scheme: dark) {
          .currOS-input:focus {
            box-shadow: 0 0 0 2px rgba(76, 194, 255, 0.2);
          }
        }

        .currOS-input.placeholder {
          color: var(--text-secondary);
          font-weight: inherit;
        }

        /* 兼容旧版 -webkit-autofill 和新版 -internal-autofill-selected */
        .currOS-input:-webkit-autofill,
        .currOS-input:-webkit-autofill:hover,
        .currOS-input:-webkit-autofill:focus,
        .currOS-input:-internal-autofill-selected {
          /* 强制覆盖背景色（通过 inset box-shadow 模拟） */
          /*
          -webkit-box-shadow: 0 0 0px 1000px transparent inset !important;
          box-shadow: 0 0 0px 1000px transparent inset !important;
          */

          /* 强制设置文本颜色 */
          -webkit-text-fill-color: var(--text-primary) !important;
          color: var(--text-primary) !important;

          /* 强制设置光标颜色 */
          /* Prompt: css input中改变cursor的颜色 */
          /* https://cloud.tencent.com/developer/article/1720528 */
          caret-color: var(--text-primary) !important;

          /* 强制设置背景颜色 */
          background-color: var(--bg-primary) !important;

          /* 防止背景色过渡动画闪烁（可选） */
          transition: background-color 5000s ease-in-out 0s;
        }

        /* =========================================
           Windows 11 Notification / Toast Styles
           ========================================= */

        /* 通知容器：模拟 Win11 右下角弹出的 Toast */
        .currOS-notification {
          position: fixed;
          bottom: 24px;
          right: 24px;
          width: 360px;
          z-index: 1000;

          /* 背景：模拟 Mica/Acrylic 材质 */
          background-color: var(--bg-surface);
          /* 关键：增加模糊效果以模拟系统材质 */
          backdrop-filter: blur(20px) saturate(120%);
          -webkit-backdrop-filter: blur(20px) saturate(120%);

          border: 1px solid var(--border-color);
          border-radius: var(--radius-md); /* 8px 圆角 */
          padding: 16px;

          /* 阴影：Win11 通知阴影较柔和 */
          box-shadow: var(--shadow-depth-8);

          display: flex;
          align-items: flex-start;
          gap: 12px;

          /* 动画：从底部滑入 */
          transform: translateY(0);
          opacity: 1;
          transition: all 0.3s ease-out;

          /* 左侧强调条 (Accent Bar) - 可选，用于区分通知类型 */
          border-left: 4px solid var(--accent-color);
        }

        /* 深色模式下的边框调整 */
        @media (prefers-color-scheme: dark) {
          .currOS-notification {
            background-color: rgba(44, 44, 44, 0.85); /* 半透明深色背景 */
            border-color: #3d3d3d;
          }
        }

        /* 通知头部：应用名称/时间 */
        .currOS-notification-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 6px;
        }

        .currOS-notification-app-name {
          font-size: var(--font-s);
          font-weight: 600;
          color: var(--text-secondary);
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .currOS-notification-time {
          font-size: var(--font-s);
          color: var(--text-secondary);
        }

        /* 通知主体 */
        .currOS-notification-title {
          font-weight: 600;
          font-size: var(--font-m);
          color: var(--text-primary);
          margin-bottom: 4px;
        }

        .currOS-notification-body {
          font-size: var(--font-s);
          color: var(--text-primary);
          line-height: 1.4;
        }

        /* 通知操作区域 */
        .currOS-notification-actions {
          display: flex;
          gap: 8px;
          margin-top: 12px;
        }

        /* Win11 风格的迷你按钮 */
        .currOS-notification-btn {
          flex: 1;
          padding: 6px 12px;
          font-size: var(--font-s);
          font-weight: 500;
          border-radius: var(--radius-sm);
          border: 1px solid var(--border-color);
          background-color: transparent;
          color: var(--text-primary);
          cursor: pointer;
          transition: background-color 0.2s ease;
        }

        .currOS-notification-btn:hover {
          background-color: var(--hover-bg);
        }

        .currOS-notification-btn.primary {
          background-color: var(--accent-color);
          color: var(--accent-text);
          border-color: transparent;
        }

        .currOS-notification-btn.primary:hover {
          background-color: var(--accent-hover);
        }

        /* 关闭图标 */
        .currOS-notification-close {
          background: none;
          border: none;
          color: var(--text-secondary);
          cursor: pointer;
          padding: 4px;
          border-radius: 4px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-left: auto; /* 推到右边 */
        }

        .currOS-notification-close:hover {
          background-color: var(--hover-bg);
          color: var(--text-primary);
        }

        /* =========================================
           Windows 11 Scrollbar Styles
           ========================================= */

        /* Webkit 内核浏览器 */
        ::-webkit-scrollbar {
          width: 14px;  /* Win11 滚动条稍宽 */
          height: 14px;
        }

        /* 滚动条轨道 (Track) */
        ::-webkit-scrollbar-track {
          background: var(--bg-primary); /* 使用主背景色，融入界面 */
          border-radius: 0; /* 轨道通常直角或微圆角，取决于容器 */
        }

        /* 滚动条滑块 (Thumb) */
        ::-webkit-scrollbar-thumb {
          background-color: #c1c1c1; /* 默认灰色 */
          border-radius: 7px;        /* 大圆角，符合 Fluent 设计 */
          border: 3px solid var(--bg-primary); /* 使用边框模拟滑块与轨道的间距 */
          background-clip: content-box;
        }

        /* 滑块悬停状态 - 使用强调色或更深灰色 */
        ::-webkit-scrollbar-thumb:hover {
          background-color: var(--accent-color); /* 悬停时变为系统强调色 */
          border-color: var(--bg-primary);
        }

        /* 滑块激活状态 */
        ::-webkit-scrollbar-thumb:active {
          background-color: var(--accent-hover);
        }

        /* 角落按钮 (Corner) - 两个滚动条交汇处 */
        ::-webkit-scrollbar-corner {
          background: var(--bg-primary);
        }

        /* 深色模式适配 */
        @media (prefers-color-scheme: dark) {
          ::-webkit-scrollbar-track {
            background: var(--bg-primary);
          }

          ::-webkit-scrollbar-thumb {
            background-color: #4a4a4a; /* 深灰色滑块 */
            border-color: var(--bg-primary);
          }

          ::-webkit-scrollbar-thumb:hover {
            background-color: var(--accent-color); /* 深色模式下强调色通常更亮 */
          }

          ::-webkit-scrollbar-corner {
            background: var(--bg-primary);
          }
        }

        /* Firefox 支持 */
        * {
          scrollbar-width: auto; /* 自动宽度，接近原生 */
          scrollbar-color: #c1c1c1 var(--bg-primary); /* thumb track */
        }

        @media (prefers-color-scheme: dark) {
          * {
            scrollbar-color: #4a4a4a var(--bg-primary);
          }
        }

        /* =========================================
           Windows 11 Explorer Style File View
           ========================================= */

        /* 容器基础 */
        .currOS-explorer-view {
          font-size: var(--font-m);
          background-color: var(--bg-primary);
          color: var(--text-primary);
          padding: 12px;
          overflow: auto;
          /* viewport height 允许webkit滚动条的出现，但此处由于父层必定有容器，就不能设置，不然容易必定出滚动条 */
          /*
          height: 100%;
          */
        }

        /* 底部状态栏 */
        .currOS-summary-bar {
          font-size: var(--font-xs);
          color: var(--text-secondary);
          padding: 2px 12px;
          border-top: 1px solid var(--border-color);
          background-color: var(--explorer-info-bg);
        }

        /* --- 视图模式：图标 (Icon View) --- */
        .currOS-view-icons {
          display: grid;
          /* 默认中等图标 */
          grid-template-columns: repeat(auto-fill, minmax(96px, 1fr));
          gap: 12px;
        }

        /* 变体：尺寸调整 */
        .currOS-view-icons.size-small {
          grid-template-columns: repeat(auto-fill, minmax(48px, 1fr));
          gap: 8px;
        }
        .currOS-view-icons.size-large {
          grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
          gap: 16px;
        }
        .currOS-view-icons.size-extra-large {
          grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
          gap: 24px;
        }

        .currOS-file-item {
          display: flex;
          flex-direction: column;
          align-items: center;
          padding: 8px;
          border: 1px solid transparent; /* 预留边框位置 */
          border-radius: var(--radius-sm);
          cursor: default;
          transition: all 0.1s ease;
          text-align: center;
          position: relative;
        }

        .currOS-file-item:hover {
          background-color: var(--hover-bg);
        }

        /* 选中状态：Win11 使用蓝色边框+浅色背景 */
        .currOS-file-item.selected {
          background-color: var(--selection-bg);
          border-color: var(--selection-border);
        }

        .currOS-file-icon {
          width: 48px;
          height: 48px;
          margin-bottom: 6px;
          object-fit: contain;
        }

        .currOS-file-name {
          font-size: var(--font-s);
          line-height: 1.4;
          word-break: break-word;
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }

        /* --- 视图模式：列表/详细信息 (Details View) --- */
        .currOS-view-details {
          display: flex;
          flex-direction: column;
          border: 1px solid var(--border-color);
          background-color: var(--bg-surface);
          border-radius: var(--radius-sm);
          overflow: hidden;
        }

        .currOS-details-header {
          /*
          display: flex;
          */
          padding: 8px 12px;
          background-color: var(--bg-primary);
          border-bottom: 1px solid var(--border-color);
          font-size: var(--font-s);
          font-weight: 600;
          color: var(--text-secondary);
        }

        .currOS-details-row {
          /*
          display: flex;
          */
          align-items: left;
          padding: 6px 12px;
          font-size: var(--font-s);
          border-bottom: 1px solid transparent;
          cursor: default;
        }

        .currOS-details-row:hover {
          background-color: var(--hover-bg);
        }

        .currOS-details-row.selected {
          background-color: var(--selection-bg);
          color: var(--text-primary);
        }

        /* 列定义 */
        .currOS-col-icon { width: 32px; flex-shrink: 0; }
        .currOS-col-name {
          flex: 2;
          display: flex;
          align-items: center;
          gap: 8px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .currOS-col-date {
          flex: 1;
          color: var(--text-secondary);
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .currOS-col-type {
          flex: 1;
          color: var(--text-secondary);
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .currOS-col-size {
          flex: 1;
          text-align: right;
          color: var(--text-secondary);
          white-space: nowrap;
        }

        /* --- 视图模式：平铺 (Tiles View) --- */
        /* 介于图标和详细信息之间，显示图标+主要元数据 */
        .currOS-view-tiles {
          display: flex;
          flex-direction: column;
          gap: 2px;
        }

        .currOS-tile-item {
          display: flex;
          align-items: center;
          padding: 8px 12px;
          border-radius: var(--radius-sm);
          cursor: default;
        }

        .currOS-tile-item:hover {
          background-color: var(--hover-bg);
        }

        .currOS-tile-item.selected {
          background-color: var(--selection-bg);
          border: 1px solid var(--selection-border);
        }

        .currOS-tile-icon {
          width: 32px;
          height: 32px;
          margin-right: 12px;
        }

        .currOS-tile-info {
          display: flex;
          flex-direction: column;
        }

        .currOS-tile-name {
          font-weight: 500;
          font-size: var(--font-s);
        }

        .currOS-tile-meta {
          font-size: var(--font-s);
          color: var(--text-secondary);
        }

        /* --- 分组样式 (Groups) --- */
        .currOS-group-header {
          display: flex;
          align-items: center;
          padding: 6px 12px;
          margin-top: 12px;
          background-color: var(--bg-primary);
          border-bottom: 1px solid var(--border-color);
          font-size: var(--font-s);
          font-weight: 600;
          color: var(--text-primary);
          cursor: pointer;
          user-select: none;
        }

        /* 折叠按钮 */
        .currOS-group-toggle {
          margin-right: 8px;
          font-size: var(--font-xs);
          color: var(--text-secondary);
          transition: transform 0.2s ease;
          display: inline-block;
        }

        /* 使用 Unicode 三角形或 SVG */
        .currOS-group-toggle::before {
          content: '▼';
          display: inline-block;
          transform: rotate(0deg);
          transition: transform 0.2s ease;
        }

        /* 折叠状态 */
        .currOS-group-header.collapsed .currOS-group-toggle::before {
          transform: rotate(-90deg);
        }

        .currOS-group-content {
          /* 继承父级布局 */
        }

        .currOS-group-content.hidden {
          display: none;
        }

        /* 分隔条样式（由td模拟得出） */
        .currOS-group-separator td {
          background-color: var(--bg-primary);
          border-top: 1px solid var(--border-color);
          padding: 12px 12px 6px 12px;
          font-size: var(--font-s);
          font-weight: 600;
          color: var(--text-primary);
          cursor: pointer;
          position: sticky;
          top: 0;
          z-index: 100;
        }
        .currOS-group-separator .group-toggle {
          display: inline-block;
          margin-right: 6px;
          transition: transform 0.2s ease;
        }
        .currOS-group-separator .group-toggle::before {
          content: '▼';
          display: inline-block;
          transition: transform 0.2s ease;
        }
        .currOS-group-separator.collapsed {
          background-color: var(--bg-primary);
          border: 1px solid var(--border-color);
        }
        .currOS-group-separator.collapsed:hover {
          background-color: var(--group-sep-bg);
          box-shadow: inset 0 0 0 9999px rgba(var(--bg-primary),1);
        }
        .currOS-group-separator.collapsed .group-toggle::before {
          transform: rotate(-90deg);
        }
        .currOS-group-separator.collapsed td {
          background-color: var(--bg-primary);
          border: 1px solid var(--border-color);
        }
        .currOS-group-separator.collapsed td:hover {
          background-color: var(--group-sep-bg);
        }

        /* =========================================
           Windows 11 Dropdown / Select Styles
           ========================================= */

        /* 触发按钮 (Trigger Button) - 模拟 Win11 ComboBox */
        .currOS-select-trigger {
          display: inline-flex;
          align-items: center;
          justify-content: space-between;
          min-width: 120px;
          padding: 8px 12px;
          background-color: var(--bg-surface);
          border: 1px solid var(--dropdown-border);
          border-radius: var(--radius-sm);
          font-size: var(--font-m);
          color: var(--text-primary);
          cursor: default;
          transition: all 0.2s ease;
        }

        .currOS-select-trigger:hover {
          border-color: var(--text-secondary);
          background-color: var(--dropdown-item-hover);
        }

        .currOS-select-trigger.active {
          border-color: var(--accent-color);
          border-bottom-left-radius: 0;
          border-bottom-right-radius: 0;
          border-bottom: 1px solid var(--bg-surface); /* 与面板连接处无缝 */
        }

        /* 下拉箭头图标 */
        .currOS-select-arrow {
          width: 12px;
          height: 12px;
          margin-left: 8px;
          fill: var(--text-primary);
          transition: transform 0.2s ease;
        }

        .currOS-select-trigger.active .currOS-select-arrow {
          transform: rotate(180deg);
        }

        /* 下拉面板 (Dropdown Panel) */
        .currOS-dropdown-menu {
          position: absolute;
          min-width: 40px;
          background-color: var(--bg-surface);
          border: 1px solid var(--dropdown-border);
          border-radius: var(--radius-md);
          /*
          border-radius: 0 0 var(--radius-sm) var(--radius-sm);
          */
          box-shadow: var(--dropdown-shadow);
          padding: 4px 0;
          z-index: 1000;
        }

        /* 下拉面板中的选项预设 */
        .currOS-dropdown-menu .currOS-dropdown-item {
          padding: 8px 12px;
        }

        /* 下拉面板中的选项列表 (Options List)，适用于有分组时的组内样式 */
        .currOS-dropdown-group-list {
          list-style: none;
          padding: 4px 0;
          margin: 0;
        }

        /* 滚动条容器 (Scroll Container)，关闭原生滚动条并使用Chrome样式滚动面板时使用 */
        .currOS-dropdown-scroll-container {
          overflow-y: auto;
          overflow-x: hidden;
          max-height: 600px;
          scrollbar-width: none;
          -ms-overflow-style: none;
        }
        .currOS-dropdown-scroll-container::-webkit-scrollbar {
          display: none;
          width: 0;
          height: 0;
        }

        /* 菜单项 (Menu Item) */
        .currOS-dropdown-item {
          position: relative;
          display: flex;
          align-items: center;
          padding: 8px 12px;
          font-size: var(--font-m);
          color: var(--text-primary);
          text-overflow: ellipsis;
          cursor: default;
          transition: background-color 0.1s ease;
        }

        /* 悬停状态 */
        .currOS-dropdown-item:hover {
          background-color: var(--dropdown-item-hover);
        }

        /* 选中状态 (Single Select) - Win11 通常在左侧显示强调色条或对勾 */
        .currOS-dropdown-item.selected {
          background: transparent;
          font-weight: 600;
          color: var(--text-primary);
        }

        /* 键盘交互 */
        .currOS-dropdown-item.keyboard-active {
          background-color: var(--dropdown-item-hover);
          outline: none;
        }
        .currOS-dropdown-item.selected.keyboard-active {
          background-color: var(--dropdown-item-hover);
        }

        /* 禁用状态 */
        .currOS-dropdown-item.disabled {
          color: var(--text-secondary);
          opacity: 0.6;
          pointer-events: none;
        }

        /* 选中标志 */
        .currOS-dropdown-indicator {
          display: inline-block;
          width: 16px;
          margin-right: 6px;
          text-align: center;
          visibility: hidden;
          font-size: inherit;
          line-height: 1;
        }
        .currOS-dropdown-item.selected .currOS-dropdown-indicator {
          visibility: visible;
        }

        /* 选项显示的标签 */
        .currOS-dropdown-item-label {
          flex: 1;
        }

        /* 多选复选框样式 (Checkbox for Multi-select) */
        .currOS-checkbox {
          width: 18px;
          height: 18px;
          border: 1px solid var(--dropdown-border);
          border-radius: 2px; /* Win11 复选框圆角较小 */
          margin-right: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          background-color: var(--bg-surface);
          transition: all 0.2s ease;
        }

        .currOS-dropdown-item:hover .currOS-checkbox {
          border-color: var(--text-primary);
        }

        .currOS-checkbox.checked {
          background-color: var(--accent-color);
          border-color: var(--accent-color);
        }

        .currOS-checkbox.checked::after {
          content: '✓';
          color: white;
          font-size: var(--font-s);
          font-weight: bold;
        }

        /* 分组标题 */
        .currOS-dropdown-group-label {
          padding: 8px 12px;
          font-size: var(--font-s);
          font-weight: 600;
          background-color: var(--dropdown-group-label-bg);
          color: var(--text-primary);
          text-transform: uppercase;
          pointer-events: none;
          letter-spacing: 0.5px;
          border-bottom: 1px solid var(--dropdown-border);
          margin-top: 2px;
        }

        /* 分隔线 */
        .currOS-dropdown-divider {
          height: 1px;
          background-color: var(--dropdown-group-label-bg);
          margin: 2px 0;
          pointer-events: none;
        }

        /* 有子菜单时的指示箭头 */
        .currOS-dropdown-submenu-arrow {
          /* margin-left 允许元素右对齐 */
          margin-left: auto;
          /* padding-left 将元素与其左边相邻的内容隔开一定距离 */
          padding-left: 12px;
          font-size: var(--font-m);
          color: var(--text-primary);
          transition: transform 150ms;
        }
        .currOS-dropdown-item:hover > .currOS-dropdown-submenu-arrow {
          color: var(--accent-color);
        }

        /* 窗口滚动指示箭头 */
        .currOS-dropdown-scroll-arrow {
          position: absolute;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: transparent;
          color: var(--text-primary);
          pointer-events: auto;
          transition: background 120ms, opacity 180ms;
          opacity: 0;
        }
        .currOS-dropdown-scroll-arrow.visible {
          opacity: 1;
        }
        .currOS-dropdown-scroll-arrow.disabled {
          opacity: 0.2;
          pointer-events: none;
          cursor: default;
          color: var(--text-disabled);
        }
        .currOS-dropdown-scroll-arrow:not(.disabled):hover {
          background-color: var(--dropdown-arrow-bg);
        }
        .currOS-dropdown-scroll-arrow:not(.disabled):active {
          background-color: var(--dropdown-arrow-bg-active);
        }

        .currOS-dropdown-arrow-icon {
          width: var(--font-m);
          height: var(--font-m);
          color: var(--text-primary);
          transition: color 150ms;
        }
        .currOS-dropdown-scroll-arrow.disabled .currOS-dropdown-arrow-icon {
          color: var(--text-secondary);
        }
        .currOS-dropdown-scroll-arrow:not(.disabled):hover .currOS-dropdown-arrow-icon {
          color: var(--accent-color);
        }

        /* =========================================
           Windows 11 Tooltip (AI designed)
           ========================================= */

        .currOS-tooltip {
          background: linear-gradient(135deg, var(--bg-surface), var(--tooltip-bg-grad));
          color: var(--text-primary);
          /* 以下均参考 Notification */
          /* 关键：增加模糊效果以模拟系统材质 */
          backdrop-filter: blur(20px) saturate(120%);
          -webkit-backdrop-filter: blur(20px) saturate(120%);

          border: 1px solid var(--border-color);
          border-radius: var(--radius-md); /* 8px 圆角 */

          /* 阴影：Win11 通知阴影较柔和 */
          box-shadow: var(--shadow-depth-8);
        }

        /* 深色模式下的边框调整 */
        @media (prefers-color-scheme: dark) {
          .currOS-tooltip {
            background: linear-gradient(135deg, rgba(44, 44, 44, 0.85), var(--tooltip-bg-grad));
            border-color: var(--tooltip-border);
          }
        }


        /* Theme Switcher Container from `scipy` */
        .tswitcher-container {
          background-color: var(--currOS-panel);
          border: 1px solid var(--currOS-border);
          border-radius: 8px;
          padding: 12px;
          margin: var(--currOS-margin);
          display: flex; flex-direction: column; gap: 8px;
          position: relative;
        }
        .tswitcher-flex-row {
          display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
        }
        .tswitcher-theme-switch {
          z-index: 10;
          margin-top: var(--currOS-margin);
          margin-right: var(--currOS-margin);
          height: calc(1em * 1.5);
          display: inline-flex; align-items: center; justify-content: center;
        }
    ''')

    #200. Style set for MacOS
    MacOS = cleandoc('''
        /* 定义全局 CSS 变量 */
        :root {
          /* 浅色模式 (Light Mode) 默认值 */
          --bg-primary: #ffffff;

          --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          --font-m: 13px;
          --font-s: 12px;
          --font-xs: 10px;
          --text-primary: #1d1d1f;
          --text-secondary: #86868b;
          /* rgba2rgb(--text-primary, alpha_in = 0.1, color_bg = --bg-primary) */
          --text-disabled: #E8E8E8;

          --border-color: #d2d2d7;
          --border-hover: rgba(0, 122, 255, 0.3);

          /* MacOS 默认蓝色强调色 */
          --accent-color: #007aff;
          --accent-text: #ffffff;

          --border-color: #d2d2d7;

          /* 悬停效果背景 */
          --hover-bg: rgba(0, 0, 0, 0.05);

          /* 按钮由快捷键触发时的脉冲特效 */
          --btn-pulse-bgn: rgba(0, 122, 255, 0.7);
          --btn-pulse-end: rgba(0, 122, 255, 0);

          --box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
          --btn-hover-shadow: 0 2px 8px rgba(0, 122, 255, 0.3);

          --radius-sm: 6px;
          --radius-md: 8px;

          --selection-bg: rgba(0, 122, 255, 0.15);
          --selection-border: #007aff;

          --sidebar-bg: #f5f5f7;

          /* 下拉菜单 */
          --dropdown-bg: #ffffff;
          --dropdown-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
          --dropdown-item-hover: #f5f5f7;
          --dropdown-arrow-bg: rgba(0, 122, 255, 0.06);
          --dropdown-arrow-bg-active: rgba(0, 122, 255, 0.08);
          /* rgba2rgb(--text-secondary, alpha_in = 0.2, color_bg = --bg-primary) */
          --dropdown-group-label-bg: #E6E6E7;
          --segment-item-bg: #ffffff;

          /* 标准按钮相关 */
          --btn-hover-bg: #f5f5f7; /* 轻微变灰 */
          --btn-active-bg: #e5e5ea;
          --btn-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
          /*
          --btn-hover-shadow: 0 2px 4px rgba(0, 0, 0, 0.15);
          */
          --btn-primary-hover-bg: #0062cc; /* 深蓝 */
          --btn-primary-active-bg: #0051a8;
          --btn-finder-active-bg: rgba(0, 0, 0, 0.1);
          --anim-transition: all 0.2s cubic-bezier(0.25, 0.8, 0.25, 1);

          /* Explorer中按钮样式 */
          --explorer-btn-height : 32px;
          --explorer-margin-adj : 2px;

          /* Explorer中分类显示详细信息时的分隔条 */
          /* 用 --text-primary 加透明度 */
          --group-sep-bg: rgba(29, 29, 31, 0.15);

          /* Explorer 底部状态栏 */
          --explorer-info-bg: rgba(29, 29, 31, 0.05);

          /* Tooltip 专属 */
          /* rgba2rgb(--text-primary, alpha_in = 0.08, color_bg = --bg-primary) */
          --tooltip-bg-grad: #ECECED;
        }

        /* 深色模式 (Dark Mode) 覆盖值 */
        @media (prefers-color-scheme: dark) {
          :root {
            /* 深灰色背景，非纯黑，符合 MacOS 设计 */
            --bg-primary: #1e1e1e;

            --text-primary: #f5f5f7;
            --text-secondary: #a1a1a6;
            /* rgba2rgb(--text-primary, alpha_in = 0.2, color_bg = --bg-primary) */
            --text-disabled: #333333;

            --border-color: #424245;
            --border-hover: rgba(10, 132, 255, 0.4);

            /* 深色模式下稍亮的蓝色 */
            --accent-color: #0a84ff;
            --accent-text: #ffffff;

            --border-color: #424245;

            --hover-bg: rgba(255, 255, 255, 0.1);

            /* 按钮由快捷键触发时的脉冲特效 */
            --btn-pulse-bgn: rgba(10, 132, 255, 0.7);
            --btn-pulse-end: rgba(10, 132, 255, 0);

            --box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
            --btn-hover-shadow: 0 2px 8px rgba(10, 132, 255, 0.4);

            --selection-bg: rgba(10, 132, 255, 0.3);
            --selection-border: #0a84ff;

            --sidebar-bg: #2a2a2a;

            /* 下拉菜单 */
            --dropdown-bg: #2c2c2e;
            --dropdown-shadow: 0 4px 16px rgba(0, 0, 0, 0.4);
            --dropdown-item-hover: #2a2a2a;
            --dropdown-arrow-bg: rgba(10, 132, 255, 0.08);
            --dropdown-arrow-bg-active: rgba(10, 132, 255, 0.1);
            /* rgba2rgb(--text-secondary, alpha_in = 0.2, color_bg = --bg-primary) */
            --dropdown-group-label-bg: #383839;
            --segment-item-bg: #4a4a4c;

            /* 标准按钮相关 */
            --btn-hover-bg: #3a3a3c;
            --btn-active-bg: #48484a;
            --btn-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
            /*
            --btn-hover-shadow: 0 2px 4px rgba(0, 0, 0, 0.4);
            */
            --btn-finder-active-bg: rgba(255, 255, 255, 0.15);

            /* Explorer中分类显示详细信息时的分隔条 */
            /* 用 --text-primary 加透明度 */
            --group-sep-bg: rgba(245, 245, 247, 0.15);

            /* Explorer 底部状态栏 */
            --explorer-info-bg: rgba(245, 245, 247, 0.01);

            /* Tooltip 专属 */
            /* rgba2rgb(--text-primary, alpha_in = 0.08, color_bg = --bg-primary) */
            --tooltip-bg-grad: #2F2F2F;
            --tooltip-border: #4a4a4a;
          }
        }

        /* 基础重置与布局 */
        body {
          background-color: var(--bg-primary);
          color: var(--text-primary);
          font-family: var(--font-family);
          margin: 0;
          padding: 20px;
          transition: background-color 0.3s ease, color 0.3s ease;
          line-height: 1.5;
        }

        /* Box 样式 (卡片/容器) */
        .currOS-box {
          background-color: var(--bg-primary);
          border: 1px solid var(--border-color);
          border-radius: 12px; /* currOSOS 大圆角风格 */
          padding: 24px;
          margin-bottom: 20px;
          box-shadow: var(--box-shadow);
          transition: border-color 0.3s ease, box-shadow 0.3s ease;
        }

        .currOS-box:hover {
          border-color: var(--accent-color);
          box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12);
        }

        /* 按钮样式 (Primary) */
        .currOS-btn {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          padding: 6px 16px;
          font-family: -apple-system, BlinkMacSystemFont, sans-serif;
          font-size: var(--font-m);
          font-weight: 500;
          color: var(--text-primary);
          background-color: var(--bg-primary);
          border: 1px solid var(--border-color);
          border-radius: 6px;
          box-shadow: var(--btn-shadow);
          cursor: default;

          /* 关键：平滑过渡 */
          transition: var(--anim-transition);
        }

        /* 悬停状态：背景变深 + 阴影轻微提升 */
        .currOS-btn:hover {
          background-color: var(--btn-hover-bg);
          filter: brightness(1.1); /* 轻微提亮 */
          border-color: var(--border-hover);
          color: var(--accent-color);
          box-shadow: var(--btn-hover-shadow);
          transform: translateY(-1px);
          /* 边框颜色通常保持不变或轻微变深，这里保持简洁 */
        }

        /* 激活/点击状态：背景更深 + 阴影内陷或减小 */
        .currOS-btn:active {
          background-color: var(--btn-active-bg);
          box-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
          transform: scale(0.98); /* 轻微缩放模拟按压感 */
          filter: brightness(0.95);
        }

        /* 焦点状态：无障碍访问关键 */
        .currOS-btn:focus {
          outline: none;
        }
        .currOS-btn:focus-visible {
          box-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
          background-color: var(--btn-hover-bg);
          outline: 1px solid var(--border-hover);
          outline-offset: 2px;
        }

        .currOS-btn.key-triggered {
          animation: btnClickPulse 0.45s ease-out;
          animation-fill-mode: none; /* 确保动画结束后不保持最终状态 */
        }
        .currOS-btn.key-triggered.clicked {
          transform: scale(0.98);
          filter: brightness(0.95);
        }

        /* 主要按钮 (Primary Button) 的特殊悬停 */
        .currOS-btn.primary {
          background-color: var(--accent-color);
          color: white;
          border-color: transparent;
        }

        .currOS-btn.primary:hover {
          background-color: var(--btn-primary-hover-bg);
          box-shadow: 0 2px 6px rgba(0, 122, 255, 0.3);
        }

        .currOS-btn.primary:active {
          background-color: var(--btn-primary-active-bg);
          transform: scale(0.98);
        }

        /* 按钮样式 (Secondary/Outline) */
        .currOS-btn-secondary {
          background-color: transparent;
          color: var(--text-primary);
          border: 1px solid var(--border-color);
          border-radius: 8px;
          padding: 10px 20px;
          margin: 10px 5px;
          font-size: var(--font-m);
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s ease;
        }

        .currOS-btn-secondary:hover {
          background-color: var(--hover-bg);
          border-color: var(--text-primary);
        }

        .currOS-btn-secondary.key-triggered {
          animation: btnClickPulse 0.45s ease-out;
          animation-fill-mode: none;
        }
        .currOS-btn-secondary.key-triggered.clicked {
          transform: scale(0.98);
          filter: brightness(0.95);
        }

        /* =========================================
           Finder 中按钮样式 对应 Explorer
           ========================================= */
        .currOS-btn-explorer {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          /* 由于我们自定义的按钮一般都有label，这里就不限定宽度了
          width: 32px;
          */
          padding-left: 8px;
          padding-right: 8px;
          height: var(--explorer-btn-height);
          border-radius: 6px; /* 圆角矩形 */
          border: 0.5px solid var(--border-color);
          font-size: var(--font-m);
          background: transparent;
          color: var(--text-primary);
          cursor: default;
          transition: background-color 0.2s ease, color 0.2s ease;
        }

        /* 悬停：显示浅灰色背景 */
        .currOS-btn-explorer:hover {
          background-color: var(--hover-bg);
          color: var(--accent-color);
          border-color: var(--border-hover);
        }

        /* 激活/点击：背景稍深 */
        .currOS-btn-explorer:active {
          background-color: var(--btn-finder-active-bg);
          transform: scale(0.98);
          filter: brightness(0.95);
          box-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
        }

        /* 焦点状态：无障碍访问关键 */
        .currOS-btn-explorer:focus {
          outline: none;
        }
        .currOS-btn-explorer:focus-visible {
          box-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
          background-color: var(--btn-hover-bg);
          outline: 1px solid var(--border-hover);
          outline-offset: 2px;
        }

        .currOS-btn-explorer.key-triggered {
          animation: btnClickPulse 0.45s ease-out;
          animation-fill-mode: none;
        }
        .currOS-btn-explorer.key-triggered.clicked {
          transform: scale(0.98);
          filter: brightness(0.95);
        }

        /* 如果按钮包含 SVG 图标，确保图标颜色随文字颜色变化 */
        .currOS-btn-explorer svg {
          fill: currentColor;
          transition: fill 0.2s ease;
        }

        /* =========================================
           Finder Segmented Control 下拉框控件
           ========================================= */
        .finder-segmented-control {
          display: inline-flex;
          background-color: var(--hover-bg);
          border-radius: 8px;
          padding: 2px;
          border: 1px solid var(--btn-finder-active-bg);
        }

        .finder-segment-item {
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 4px 12px;
          font-size: var(--font-s);
          font-weight: 500;
          color: var(--text-secondary);
          border-radius: 6px;
          cursor: default;
          transition: all 0.2s ease;
          position: relative;
        }

        /* 悬停：未选中项显示轻微背景 */
        .finder-segment-item:hover:not(.selected) {
          background-color: var(--hover-bg);
          color: var(--text-primary);
        }

        /* 选中状态：白色背景 + 阴影 (浅色模式) */
        .finder-segment-item.selected {
          background-color: var(--segment-item-bg);
          color: var(--text-primary);
          box-shadow: var(--btn-shadow);
        }

        /* 选中项悬停时保持选中状态，不额外变化 */
        .finder-segment-item.selected:hover {
          background-color: inherit;
        }

        /* =========================================
           输入框样式 (模拟 macOS 表单)
           ========================================= */
        .currOS-input {
          width: 100%;
          padding: 10px 12px;
          margin: 10px 2px;
          border: 1px solid var(--border-color);
          border-radius: 8px;
          background-color: var(--bg-primary);
          color: var(--text-primary);
          caret-color: var(--text-primary);
          font-size: var(--font-m);
          box-sizing: border-box;
          transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }

        .currOS-input:hover {
          border-color: var(--accent-color);
          box-shadow: 0 0 0 1px var(--border-hover);
        }

        .currOS-input:focus {
          outline: none;
          border-color: var(--accent-color);
          color: var(--text-primary);
          /* 聚焦时的光晕效果 */
          /*
          box-shadow: 0 0 0 4px rgba(0, 122, 255, 0.2);
          */
          box-shadow: 0 0 0 4px var(--selection-bg);
        }

        .currOS-input.placeholder {
          color: var(--text-secondary);
          font-weight: inherit;
        }

        /* 文本高亮模拟 (选中文本颜色) */
        ::selection {
          background-color: var(--accent-color);
          color: var(--accent-text);
        }

        /* 兼容旧版 -webkit-autofill 和新版 -internal-autofill-selected */
        .currOS-input:-webkit-autofill,
        .currOS-input:-webkit-autofill:hover,
        .currOS-input:-webkit-autofill:focus,
        .currOS-input:-internal-autofill-selected {
          /* 强制覆盖背景色（通过 inset box-shadow 模拟） */
          -webkit-box-shadow: 0 0 0px 1000px transparent inset !important;
          box-shadow: 0 0 0px 1000px transparent inset !important;

          /* 强制设置文本颜色 */
          -webkit-text-fill-color: var(--text-primary) !important;
          color: var(--text-primary) !important;

          /* 强制设置光标颜色 */
          /* Prompt: css input中改变cursor的颜色 */
          /* https://cloud.tencent.com/developer/article/1720528 */
          caret-color: var(--text-primary) !important;

          /* 强制设置背景颜色 */
          background-color: var(--bg-primary) !important;

          /* 防止背景色过渡动画闪烁（可选） */
          transition: background-color 5000s ease-in-out 0s;
        }

        /* =========================================
           macOS Notification / Toast Styles
           ========================================= */

        /* 通知容器：模拟 macOS 通知中心的卡片 */
        .currOS-notification {
          position: fixed;
          top: 20px;
          right: 20px;
          width: 320px;
          z-index: 1000;

          /* 背景：浅色模式下略带透明，深色模式下更实 */
          background-color: var(--bg-surface);
          /* 如果希望更像原生，可以使用 backdrop-filter，但需确保背景有内容 */
          backdrop-filter: blur(20px);

          border: 1px solid var(--border-color);
          border-radius: 14px; /* macOS 大圆角 */
          padding: 16px;

          /* 阴影：macOS 通知具有较深的投影以突出层级 */
          box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12), 0 2px 6px rgba(0, 0, 0, 0.08);

          display: flex;
          align-items: flex-start;
          gap: 12px;

          /* 动画：滑入效果 */
          transform: translateX(0);
          opacity: 1;
          transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
        }

        /* 深色模式下的阴影调整 */
        @media (prefers-color-scheme: dark) {
          .currOS-notification {
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4), 0 2px 6px rgba(0, 0, 0, 0.2);
            border-color: #4a4a4a;
          }
        }

        /* 通知图标区域 */
        .currOS-notification-icon {
          width: 36px;
          height: 36px;
          border-radius: 8px;
          background-color: var(--hover-bg);
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 18px;
          flex-shrink: 0;
        }

        /* 通知内容区域 */
        .currOS-notification-content {
          flex: 1;
        }

        .currOS-notification-title {
          font-weight: 600;
          font-size: 14px;
          color: var(--text-primary);
          margin-bottom: 4px;
        }

        .currOS-notification-body {
          font-size: var(--font-m);
          color: var(--text-secondary);
          line-height: 1.4;
        }

        /* 通知操作按钮 (可选) */
        /* 原为 .currOS-notification-action */
        .currOS-notification-btn {
          margin-top: 8px;
          font-size: var(--font-s);
          color: var(--accent-color);
          background: none;
          border: none;
          cursor: pointer;
          padding: 0;
          font-weight: 500;
        }

        .currOS-notification-btn:hover {
          text-decoration: underline;
        }

        /* 关闭按钮 */
        .currOS-notification-close {
          background: none;
          border: none;
          color: var(--text-secondary);
          cursor: pointer;
          padding: 4px;
          border-radius: 4px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .currOS-notification-close:hover {
          background-color: var(--hover-bg);
          color: var(--text-primary);
        }

        /* =========================================
           macOS Scrollbar Styles
           ========================================= */

        /* 针对 Webkit 内核浏览器 (Chrome, Safari, Edge, Firefox 新版) */
        ::-webkit-scrollbar {
          width: 10px;  /* 垂直滚动条宽度 */
          height: 10px; /* 水平滚动条高度 */
        }

        /* 滚动条轨道 (Track) - macOS 通常透明或极淡 */
        ::-webkit-scrollbar-track {
          background: transparent;
          border-radius: 10px;
        }

        /* 滚动条滑块 (Thumb) */
        ::-webkit-scrollbar-thumb {
          background-color: rgba(0, 0, 0, 0.2); /* 浅色模式：半透明黑 */
          border-radius: 10px;
          border: 2px solid transparent; /* 创建内边距效果，使滑块看起来更细 */
          background-clip: content-box;
        }

        /* 滑块悬停状态 */
        ::-webkit-scrollbar-thumb:hover {
          background-color: var(--accent-color);
        }

        /* 滑块激活/拖动状态 */
        ::-webkit-scrollbar-thumb:active {
          background-color: rgba(0, 0, 0, 0.6);
        }

        /* 深色模式适配 */
        @media (prefers-color-scheme: dark) {
          ::-webkit-scrollbar-thumb {
            background-color: rgba(255, 255, 255, 0.2); /* 深色模式：半透明白 */
          }

          ::-webkit-scrollbar-thumb:hover {
            background-color: rgba(255, 255, 255, 0.4);
          }

          ::-webkit-scrollbar-thumb:active {
            background-color: rgba(255, 255, 255, 0.6);
          }
        }

        /* Firefox 支持 (标准属性) */
        * {
          scrollbar-width: thin; /* 细滚动条 */
          scrollbar-color: rgba(0, 0, 0, 0.2) transparent; /* thumb track */
        }

        @media (prefers-color-scheme: dark) {
          * {
            scrollbar-color: rgba(255, 255, 255, 0.2) transparent;
          }
        }

        /* =========================================
           macOS Finder (a.k.a. Explorer) Style File View
           ========================================= */

        /* 容器基础 */
        .currOS-explorer-view {
          background-color: var(--bg-primary);
          color: var(--text-primary);
          padding: 16px;
          overflow-y: auto;
          height: 100%;
        }

        /* 底部状态栏 */
        .currOS-summary-bar {
          font-size: var(--font-xs);
          color: var(--text-secondary);
          padding: 2px 12px;
          border-top: 1px solid var(--border-color);
          background-color: var(--explorer-info-bg);
        }

        /* --- 视图模式：图标 (Icon View) --- */
        /* 支持小、中、大、超大图标，通过 grid-template-columns 控制密度 */
        .currOS-view-icons {
          display: grid;
          /* 默认中等图标：100px */
          grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
          gap: 16px;
        }

        /* 变体：通过类名切换尺寸 */
        .currOS-view-icons.size-small {
          grid-template-columns: repeat(auto-fill, minmax(64px, 1fr));
          gap: 12px;
        }
        .currOS-view-icons.size-large {
          grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
          gap: 24px;
        }
        .currOS-view-icons.size-extra-large {
          grid-template-columns: repeat(auto-fill, minmax(256px, 1fr));
          gap: 32px;
        }

        .currOS-file-item {
          display: flex;
          flex-direction: column;
          align-items: center;
          padding: 8px;
          border-radius: var(--radius-sm);
          cursor: default;
          transition: background-color 0.2s ease;
          text-align: center;
        }

        .currOS-file-item:hover {
          background-color: var(--hover-bg);
        }

        .currOS-file-item.selected {
          background-color: var(--selection-bg);
          outline: 1px solid var(--selection-border);
        }

        .currOS-file-icon {
          width: 64px; /* 随 size 类变化 */
          height: 64px;
          margin-bottom: 8px;
          object-fit: contain;
          /* 阴影模拟图标立体感 */
          filter: drop-shadow(0 2px 4px rgba(0,0,0,0.1));
        }

        .currOS-file-name {
          font-size: var(--font-m);
          line-height: 1.4;
          word-break: break-word;
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }

        /* --- 视图模式：列表 (List View) --- */
        .currOS-view-details {
          display: flex;
          flex-direction: column;
        }

        .currOS-details-header {
          /*
          display: flex;
          */
          padding: 8px 12px;
          border-bottom: 1px solid var(--border-color);
          font-size: var(--font-s);
          color: var(--text-secondary);
          font-weight: 600;
          position: sticky;
          top: 0;
          background-color: var(--bg-primary);
          z-index: 10;
        }

        .currOS-details-row {
          /*
          display: flex;
          */
          align-items: center;
          padding: 6px 12px;
          border-bottom: 1px solid transparent; /* 占位 */
          font-size: var(--font-s);
          cursor: default;
        }

        .currOS-details-row:hover {
          background-color: var(--hover-bg);
          border-radius: var(--radius-sm);
        }

        .currOS-details-row.selected {
          background-color: var(--selection-bg);
          color: var(--text-primary);
        }

        /* <kind> is similar to <type> in Windows */
        .currOS-col-name { flex: 2; display: flex; align-items: center; gap: 8px; }
        .currOS-col-date { flex: 1; color: var(--text-secondary); }
        .currOS-col-size { flex: 1; text-align: right; color: var(--text-secondary); }
        .currOS-col-type { flex: 1; color: var(--text-secondary); }

        /* --- 视图模式：列 (Column View - 简化版) --- */
        /* 通常用于 Cover Flow 或 Column，此处模拟基本结构 */
        .currOS-view-column {
          display: flex;
          height: 100%;
        }
        .currOS-column-pane {
          flex: 1;
          border-right: 1px solid var(--border-color);
          padding: 8px;
          overflow-y: auto;
        }

        /* --- 分组样式 (Groups) --- */
        .currOS-group-header {
          display: flex;
          align-items: center;
          padding: 8px 0;
          margin-top: 16px;
          font-size: var(--font-s);
          font-weight: 600;
          color: var(--text-secondary);
          cursor: pointer;
          user-select: none;
        }

        /* 折叠按钮 (Chevron) */
        .currOS-group-toggle {
          width: 16px;
          height: 16px;
          margin-right: 8px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          transition: transform 0.2s ease;
        }

        /* 使用 SVG 或 CSS 绘制箭头 */
        .currOS-group-toggle::after {
          content: '▼';
          display: block;
          width: 6px;
          height: 6px;
          border-left: 1.5px solid var(--text-secondary);
          border-bottom: 1.5px solid var(--text-secondary);
          transform: rotate(-45deg);
          margin-left: 4px;
        }

        /* 折叠状态 */
        .currOS-group-header.collapsed .currOS-group-toggle {
          transform: rotate(-90deg); /* 箭头指向右侧 */
        }

        /* 分隔条样式（由td模拟得出） */
        .currOS-group-separator td {
          background-color: var(--bg-primary);
          border-top: 1px solid var(--border-color);
          padding: 12px 12px 6px 12px;
          font-size: var(--font-s);
          font-weight: 600;
          color: var(--text-secondary);
          cursor: pointer;
          position: sticky;
          top: 0;
          z-index: 100;
        }
        .currOS-group-separator .group-toggle {
          display: inline-block;
          margin-right: 6px;
          transition: transform 0.2s ease;
        }
        .currOS-group-separator .group-toggle::before {
          content: '▼';
          display: inline-block;
          transition: transform 0.2s ease;
        }
        .currOS-group-separator.collapsed {
          background-color: var(--bg-primary);
          border: 1px solid var(--border-color);
        }
        .currOS-group-separator.collapsed:hover {
          background-color: var(--group-sep-bg);
          box-shadow: inset 0 0 0 9999px rgba(var(--bg-primary),1);
        }
        .currOS-group-separator.collapsed .group-toggle::before {
          transform: rotate(-90deg);
        }
        .currOS-group-separator.collapsed td {
          background-color: var(--bg-primary);
          border: 1px solid var(--border-color);
        }
        .currOS-group-separator.collapsed td:hover {
          background-color: var(--group-sep-bg);
        }

        .currOS-group-content {
          display: grid; /* 或 flex，取决于父容器视图模式 */
          /* 继承父级的 grid 设置 */
        }

        .currOS-group-content.hidden {
          display: none;
        }

        /* =========================================
           macOS Dropdown / Select Styles
           ========================================= */

        /* 触发按钮 (Trigger Button) - 模拟 macOS Pop-up Button */
        .currOS-select-trigger {
          display: inline-flex;
          align-items: center;
          justify-content: space-between;
          min-width: 120px;
          padding: 6px 12px;
          background-color: var(--dropdown-bg);
          border: 1px solid var(--border-color);
          border-radius: var(--radius-md);
          font-size: var(--font-m);
          color: var(--text-primary);
          cursor: default;
          box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
          transition: all 0.2s ease;
        }

        .currOS-select-trigger:hover {
          border-color: var(--accent-color);
        }

        .currOS-select-trigger.active {
          border-color: var(--accent-color);
          box-shadow: 0 0 0 2px rgba(0, 122, 255, 0.2);
        }

        /* 下拉箭头图标 */
        .currOS-select-arrow {
          width: 12px;
          height: 12px;
          margin-left: 8px;
          fill: var(--text-secondary);
          transition: transform 0.2s ease;
        }

        .currOS-select-trigger.active .currOS-select-arrow {
          transform: rotate(180deg);
        }

        /* 下拉面板 (Dropdown Panel) */
        .currOS-dropdown-menu {
          position: absolute;
          /*
          top: 100%;
          left: 0;
          */
          min-width: 40px;
          background-color: var(--dropdown-bg);
          border: 1px solid var(--border-color);
          border-radius: var(--radius-md);
          box-shadow: var(--dropdown-shadow);
          padding: 4px 0;
          z-index: 1000;
          /*
          overflow: hidden;
          */
          backdrop-filter: blur(20px); /* 模拟半透明效果 */
        }

        /* 下拉面板中的选项预设 */
        .currOS-dropdown-menu .currOS-dropdown-item {
          padding: 6px 12px;
        }

        /* 下拉面板中的选项列表 (Options List)，适用于有分组时的组内样式 */
        .currOS-dropdown-group-list {
            list-style: none;
            padding: 6px 0;
            margin: 0;
        }

        /* 滚动条容器 (Scroll Container)，关闭原生滚动条并使用Chrome样式滚动面板时使用 */
        .currOS-dropdown-scroll-container {
          overflow-y: auto;
          overflow-x: hidden;
          max-height: 400px;
          scrollbar-width: none;
          -ms-overflow-style: none;
        }
        .currOS-dropdown-scroll-container::-webkit-scrollbar {
          display: none;
          width: 0;
          height: 0;
        }

        /* 菜单项 (Menu Item) */
        .currOS-dropdown-item {
          position: relative;
          display: flex;
          align-items: center;
          padding: 6px 12px;
          font-size: var(--font-m);
          color: var(--text-primary);
          text-overflow: ellipsis;
          cursor: default;
          transition: background-color 0.1s ease, color 0.1s ease;
        }

        /* 悬停状态 */
        .currOS-dropdown-item:hover {
          background-color: var(--accent-color);
          color: var(--accent-text);
        }

        /* 选中状态 (Single Select) - Win11 通常在左侧显示强调色条或对勾 */
        .currOS-dropdown-item.selected {
          background: transparent;
          font-weight: 600;
          color: var(--accent-text);
        }

        /* 键盘交互 */
        .currOS-dropdown-item.keyboard-active {
          background-color: var(--dropdown-item-hover);
          outline: none;
        }
        .currOS-dropdown-item.selected.keyboard-active {
          background-color: var(--dropdown-item-hover);
        }

        /* 禁用状态 */
        .currOS-dropdown-item.disabled {
          color: var(--text-secondary);
          opacity: 0.6;
          pointer-events: none;
        }

        /* 选中状态指示器 (Checkmark) - 单选 */
        .currOS-dropdown-item.selected::before {
          /*
          content: '●';
          position: absolute;
          left: 12px;
          font-weight: bold;
          */
          color: var(--accent-text); /* 悬停时白色，非悬停时需调整 */
          opacity: 0;
          transition: opacity 0.2s ease;
        }

        /* 如果未悬停但被选中，显示蓝色对勾或灰色对勾，这里简化为悬停时显示白色 */
        .currOS-dropdown-item.selected:not(:hover)::before {
          color: var(--accent-color);
          opacity: 1;
        }

        .currOS-dropdown-item.selected:hover::before {
          opacity: 1;
        }

        /* 选中标志 */
        .currOS-dropdown-indicator {
          display: inline-block;
          width: 16px;
          margin-right: 6px;
          text-align: center;
          visibility: hidden;
          font-size: inherit;
          line-height: 1;
        }
        .currOS-dropdown-item.selected .currOS-dropdown-indicator {
          visibility: visible;
        }

        /* 选项显示的标签 */
        .currOS-dropdown-item-label {
          flex: 1;
        }

        /* 调整文本缩进以容纳对勾 */
        .currOS-dropdown-item.has-icon {
          padding-left: 28px;
        }

        /* 多选复选框样式 (Checkbox for Multi-select) */
        .currOS-checkbox {
          width: 16px;
          height: 16px;
          border: 1px solid var(--border-color);
          border-radius: 4px;
          margin-right: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          background-color: var(--dropdown-bg);
          transition: all 0.2s ease;
        }

        .currOS-dropdown-item:hover .currOS-checkbox {
          border-color: var(--accent-text);
        }

        .currOS-checkbox.checked {
          background-color: var(--accent-color);
          border-color: var(--accent-color);
        }

        .currOS-checkbox.checked::after {
          content: '✓';
          color: white;
          font-size: var(--font-xs);
          font-weight: bold;
        }

        /* 分组标题 */
        .currOS-dropdown-group-label {
          padding: 6px 12px;
          font-size: var(--font-s);
          font-weight: 600;
          background-color: var(--dropdown-group-label-bg);
          color: var(--text-primary);
          text-transform: uppercase;
          letter-spacing: 0.5px;
          pointer-events: none;
          margin-top: 2px;
        }

        /* 分隔线 */
        .currOS-dropdown-divider {
          height: 1px;
          background-color: var(--dropdown-group-label-bg);
          margin: 2px 0;
          pointer-events: none;
        }

        /* 有子菜单时的指示箭头 */
        .currOS-dropdown-submenu-arrow {
          /* margin-left 允许元素右对齐 */
          margin-left: auto;
          /* padding-left 将元素与其左边相邻的内容隔开一定距离 */
          padding-left: 16px;
          font-size: var(--font-m);
          color: var(--text-primary);
          transition: transform 150ms;
        }
        .currOS-dropdown-item:hover > .currOS-dropdown-submenu-arrow {
          color: var(--accent-color);
        }

        /* 窗口滚动指示箭头 */
        .currOS-dropdown-scroll-arrow {
          position: absolute;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: transparent;
          color: var(--text-primary);
          pointer-events: auto;
          transition: background 120ms, opacity 180ms;
          opacity: 0;
        }
        .currOS-dropdown-scroll-arrow.visible {
          opacity: 1;
        }
        .currOS-dropdown-scroll-arrow.disabled {
          opacity: 0.4;
          pointer-events: none;
          cursor: default;
          color: var(--text-disabled);
        }
        .currOS-dropdown-scroll-arrow:not(.disabled):hover {
          background-color: var(--dropdown-arrow-bg);
        }
        .currOS-dropdown-scroll-arrow:not(.disabled):active {
          background-color: var(--dropdown-arrow-bg-active);
        }

        .currOS-dropdown-arrow-icon {
          width: var(--font-m);
          height: var(--font-m);
          color: var(--text-primary);
          transition: color 150ms;
        }
        .currOS-dropdown-scroll-arrow.disabled .currOS-dropdown-arrow-icon {
          color: var(--text-secondary);
        }
        .currOS-dropdown-scroll-arrow:not(.disabled):hover .currOS-dropdown-arrow-icon {
          color: var(--accent-color);
        }

        /* =========================================
           macOS Tooltip (AI designed)
           ========================================= */

        .currOS-tooltip {
          background: linear-gradient(135deg, var(--bg-surface), var(--tooltip-bg-grad));
          color: var(--text-primary);
          /* 背景：浅色模式下略带透明，深色模式下更实 */
          /* 如果希望更像原生，可以使用 backdrop-filter，但需确保背景有内容 */
          backdrop-filter: blur(20px);

          border: 1px solid var(--border-color);
          border-radius: 14px; /* macOS 大圆角 */

          /* 阴影：macOS 通知具有较深的投影以突出层级 */
          box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12), 0 2px 6px rgba(0, 0, 0, 0.08);
        }

        /* 深色模式下的阴影调整 */
        @media (prefers-color-scheme: dark) {
          .currOS-tooltip {
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4), 0 2px 6px rgba(0, 0, 0, 0.2);
            border-color: #4a4a4a;
          }
        }

    ''')

    #220. Method to enable slicing fashion during operation on APIs
    #Quote: https://www.liaoxuefeng.com/wiki/1016959663602400/1017590712115904
    def __getitem__(self, attr):
        return(getattr(self, attr))
#End OSThemesCSS

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #100.   Create envionment.
    import os
    import sys
    import pandas as pd
    import datetime as dt
    import types, asyncio, queue, threading, inspect
    from functools import partial
    from collections.abc import Iterable
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Styles import OSThemesCSS

    #[ASSUMPTION]
    #[1] `__getitem__` method only works for an instance instead of a class itself
    #[2] If you need a parametric usage
    #    [1] Initialize the instance then use `__getitem__` to pass string
    #    [2] Use the function `getattr()` upon the class
    print(OSThemesCSS.Windows)

    print(getattr(OSThemesCSS, 'Windows'))

    osThemesCSS = OSThemesCSS()
    print(osThemesCSS['Windows'])

    #200. Obtain all available presets in this class
    #[ASSUMPTION]
    #[1] Below calls are the same for simple implementation
    print(OSThemesCSS.presets)
    # print(osThemesCSS.presets)
    # {'MacOS','Windows'}

#-Notes- -End-

#-Skeleton- -Begin-
最新MacOS的系统配色是怎样的？请提供一套CSS，支持light和dark主题，至少包括: background-color, color, border-color,
对应的hover效果, margin, padding, 按钮样式, box样式

百度文心
===============================================================================
截至 2026 年中，最新的 MacOS 系统（如 MacOS 26 Tahoe 及后续版本）在配色方案上引入了更深层的自定义能力，
核心设计理念围绕“Liquid Glass”（液态玻璃）质感、动态色调统一以及独立的强调色设置。

最新 MacOS 系统配色特点

基础主题模式‌：

Light（浅色）‌：明亮的背景，适合光线充足环境，界面元素清晰清爽。
Dark（深色）‌：深灰/黑色背景，降低眼部疲劳，突出内容本身，窗口和控制项隐入背景。
Auto（自动）‌：根据日出日落时间自动切换。

新增自定义维度‌：

强调色（Accent Color）‌：用户可独立设置系统级的强调色（如蓝、紫、绿、红等或自定义），该颜色应用于按钮、选中状态、进度条等交互元素。
文本高亮色（Text Highlight Color）‌：允许将选中文本的背景色与界面其他强调色区分开，提供更高的可读性定制。
图标与文件夹色调（Tinting）‌：支持对应用图标、小组件和文件夹进行统一的色调渲染（Tinted），包括“Clear”（透明液态玻璃效果）、“Dark”（深色背景）
和“Tinted”（跟随强调色）模式。

视觉风格‌：

采用半透明、模糊（Vibrancy）和细微边框来营造层次感。
默认强调色通常为蓝色，但系统 UI 组件会根据所选主题色动态调整。
CSS 实现方案：支持 Light/Dark 主题

以下是一套基于现代 CSS 标准的样式方案，使用 :root 变量定义颜色，并通过 @media (prefers-color-scheme) 媒体查询自动适配 macOS 的系统级主题设置。
这套代码模拟了 currOSOS 原生控件的视觉风格（圆角、微妙边框、悬停反馈）。

代码说明

媒体查询 (@media (prefers-color-scheme: dark))‌：

这是检测 MacOS 系统级外观设置（浅色/深色）的标准方法。当用户在“系统设置”>“外观”中切换模式时，浏览器会自动应用对应的 CSS 变量值，
无需 JavaScript 干预。

CSS 变量 (:root)‌：

通过定义语义化的变量（如 --bg-color, --accent-color），可以确保整个页面的一致性，并简化维护。
Accent Color‌：模拟了 currOSOS 的“强调色”功能。如果需要完全匹配用户设置的特定强调色（如紫色或绿色），目前 CSS 无法直接读取系统具体的强调色值，
因此这里使用了 currOSOS 默认的蓝色系作为基准，你可以根据品牌需求调整 --accent-color 的值。

视觉细节‌：

Border Radius‌：使用了 8px-12px 的圆角，符合 currOSOS Big Sur 及之后版本的设计语言。
Transitions‌：添加了平滑的颜色过渡，使主题切换时不显突兀。
Shadows‌：深色模式下的阴影更深，浅色模式下更柔和，以维持层次感。
Hover Effects‌：按钮和卡片在悬停时有轻微的位移和阴影变化，提供清晰的交互反馈。

兼容性‌：

prefers-color-scheme 已被所有现代浏览器（Safari 12.1+, Chrome 76+, Firefox 67+）广泛支持，完美适配 MacOS 环境。

===============================================================================
Windows 11 的设计语言核心是 ‌Fluent Design‌，其特点是使用半透明材质（Mica/Acrylic）、圆角（Rounded Corners）、微妙的阴影以及清晰的层级感。
最新的 Windows 11 主题配色在浅色模式下偏向洁净的白色与浅灰，深色模式下则采用深灰而非纯黑，以减少视觉疲劳并突出内容。

以下是一套基于 Windows 11 Fluent Design 规范的 CSS 方案，支持通过 prefers-color-scheme 自动适配系统的 Light/Dark 模式。

Windows 11 Fluent Design CSS 主题方案

设计要点解析

色彩系统 (Color System)‌：

Background‌: Windows 11 不再使用纯白 (#FFFFFF) 作为应用主背景，而是使用 #F3F3F3 (Light) 和 #202020 (Dark) 来模拟 ‌Mica‌ 材质效果，
 这种颜色能更好地与桌面壁纸融合。
Surface‌: 卡片和弹窗使用更亮的 #FFFFFF (Light) 或 #2C2C2C (Dark) 以形成层级对比。
Accent‌: 默认使用 Windows 11 的标准蓝 #0067C0。在深色模式下，为了提高可读性，强调色会变得更亮 (#4CC2FF)，且文字颜色反转为黑色。

形状与圆角 (Shape & Radius)‌：

Windows 11 的核心视觉特征是圆角。代码中定义了 --radius-sm: 4px (用于按钮)、--radius-lg: 12px (用于卡片/窗口)，这符合 Fluent Design 的网格系统。

交互反馈 (Interaction)‌：

Hover‌: 使用 rgba 半透明色作为悬停背景，而不是完全改变颜色，这样能保持界面的通透感。
Transition‌: 所有颜色变化都添加了 0.2s ease 的过渡，使交互更加平滑自然，避免生硬跳变。
Focus‌: 为键盘用户提供了清晰的 outline 或 box-shadow 聚焦环，符合无障碍设计标准。

字体 (Typography)‌：

优先使用 Segoe UI Variable，这是 Windows 11 引入的新可变字体，能根据字号自动优化字重和间距，提供更佳的阅读体验。

这套 CSS 可以直接嵌入你的项目中，浏览器会根据操作系统的主题设置自动切换外观。

能否在上述两套方案中分别添加操作系统中notification的样式？
===============================================================================
在 macOS 和 Windows 11 的设计语言中，通知（Notification）或 toast 提示通常具有独特的视觉层级：它们悬浮于内容之上，拥有更高的阴影深度、
特定的圆角以及清晰的交互状态。

以下是针对之前两套方案的扩展，分别添加了符合各自系统规范的 ‌Notification/Toast 样式‌。

1. macOS 通知样式 (macOS Notification Style)

macOS 的通知中心风格倾向于“卡片化”，使用显著的阴影来营造悬浮感，背景通常带有轻微的半透明效果（在 Web 中模拟为纯色或轻微透明度），且强调色用于操作按钮或图标。

2. Windows 11 通知样式 (Windows 11 Fluent Notification Style)

Windows 11 的通知遵循 Fluent Design，特点是更方正但带有 4px-8px 的圆角，使用 ‌Mica‌ 或 ‌Acrylic‌ 材质感（Web 中用半透明背景+模糊模拟），
并且强调色通常体现在左侧的 accent bar 或图标上。

关键设计差异说明

位置与动画‌：

macOS‌：通知通常出现在屏幕右上角（或左上角，取决于语言设置），动画多为水平滑入或淡入。
Windows 11‌：通知严格位于屏幕右下角（任务栏上方），动画为垂直向上滑入。

材质与背景‌：

macOS‌：倾向于不透明的卡片或极轻微的半透明，重点在于阴影的深度 (box-shadow) 来区分层级。
Windows 11‌：强烈依赖 ‌Acrylic/Mica‌ 材质，因此在 CSS 中加入了 backdrop-filter: blur() 和半透明背景色，这是 Fluent Design 的灵魂。

视觉强调‌：

macOS‌：强调色主要用于按钮文本或图标，整体保持洁净。
Windows 11‌：常在左侧添加一条 ‌Accent Bar‌（强调色边框），或者在按钮上使用实心强调色背景，以快速传达通知的状态（如成功、警告）。

圆角‌：

macOS‌：更大的圆角 (14px)，感觉更柔和。
Windows 11‌：标准的 8px 圆角，感觉更现代且紧凑。

你可以将这两段代码分别追加到之前的 macOS 和 Windows 11 CSS 方案中，即可在网页中模拟出原生的系统通知体验。


请在此基础上提供两组对应的滚动条样式CSS
===============================================================================
基于 macOS 和 Windows 11 的设计规范，滚动条（Scrollbar）是系统 UI 中极具辨识度的组件。macOS 倾向于“隐藏式”或极简的悬浮滚动条，
而 Windows 11 则保留了更传统但经过现代化改良的轨道式滚动条。

以下是针对之前两套主题方案的滚动条样式 CSS 扩展。

1. macOS 风格滚动条 (macOS Style Scrollbar)

macOS 的滚动条特点是：

默认隐藏‌：在不交互时完全不可见。
悬浮叠加‌：出现时悬浮在内容之上，不占用布局空间（overlay）。
极简圆角‌：细长的圆角滑块，无背景轨道或极淡的轨道。
动态宽度‌：通常较窄（约 6-10px）。

2. Windows 11 风格滚动条 (Windows 11 Fluent Scrollbar)

Windows 11 的滚动条特点是：

固定轨道‌：拥有明确的背景轨道颜色。
现代圆角‌：滑块和轨道都有明显的圆角（约 4-8px）。
强调色交互‌：滑块在悬停或激活时可能会使用系统的强调色（Accent Color），或者保持灰色但变深。
层级感‌：滑块略高于轨道，有轻微的阴影或边框区分。

设计细节说明

兼容性处理‌：

::-webkit-scrollbar 系列伪元素适用于 Chrome, Safari, Edge, Opera 以及新版 Firefox。
scrollbar-width 和 scrollbar-color 是 W3C 标准属性，主要用于 Firefox，但越来越多的浏览器开始支持。为了最佳效果，建议同时编写两套。

macOS 的“隐形”技巧‌：

通过设置 background: transparent 给轨道，并使用 border + background-clip: content-box 给滑块，可以模拟出 macOS 那种滑块周围有留白、
且不显示轨道背景的视觉效果。
在 macOS 上，用户习惯滚动条在不使用时消失。CSS 无法完全实现“不交互时隐藏”，但可以通过降低透明度 (rgba(..., 0.2)) 来模拟这种低调的存在感。

Windows 11 的“强调色”交互‌：

Windows 11 的原生滚动条在悬停时通常会变色。在 CSS 中，我们将 :hover 状态绑定到 --accent-color 变量，这样如果用户更改了系统的强调色
（通过 JS 动态更新 CSS 变量），滚动条也会随之变化，提供一致的系统体验。
使用 border 来模拟滑块与轨道之间的间隙（Gutter），这是 Windows 11 滚动条的一个显著视觉特征，使滑块看起来像是浮在轨道上。

圆角一致性‌：

macOS 滑块圆角较大（10px），以匹配其柔和的 UI。
Windows 11 滑块圆角适中（7px），与其 4px-8px 的控件圆角规范保持一致。

将这两段代码分别添加到之前的 macOS 和 Windows 11 主题 CSS 中，即可实现完整的系统级滚动条体验。


请在此基础上提供两组对应的资源管理器内文件显示样式CSS，含'超大图标'、'大图标'、'中图标'、'小图标'、'列表'、'详细信息'、'平铺'、'内容'
等显示方式时样式的变化，以及分组显示时相关组件的样式（如折叠按钮等）
===============================================================================
以下是基于 macOS 和 Windows 11 设计语言的文件资源管理器视图样式 CSS。这两套方案分别模拟了各自系统在“图标”、“列表”、“详细信息”等不同视图模式下的
布局、间距、字体层级以及分组折叠交互效果。

1. macOS Finder 风格文件视图 CSS

macOS Finder 的特点是极简、大留白、圆角选中状态，以及在“图标视图”下网格对齐的流畅感。“分组”通常表现为带有折叠箭头的小标题栏。

2. Windows 11 资源管理器风格文件视图 CSS

Windows 11 Fluent Design 强调清晰的网格、明确的选中边框、Acrylic 材质感（在 Web 中用半透明模拟）以及更紧凑的“详细信息”视图。
分组通常表现为带有背景色的标题栏。

代码实现功能与特点

多视图模式支持‌：

图标视图 (Icons)‌：使用 CSS Grid (grid-template-columns) 实现响应式布局。通过 .size-small, .size-large 等类名动态调整 minmax 值，
从而模拟“小、中、大、超大”图标的密度变化。
列表/详细信息视图 (Details)‌：使用 Flexbox 模拟表格行。定义了明确的列宽比例（如名称占 2 份，日期占 1 份），并添加了文本溢出省略号
(text-overflow: ellipsis) 以处理长文件名。
平铺视图 (Tiles)‌：结合了图标和元数据，横向排列，适合快速浏览文件类型和大小。

系统级视觉规范‌：

macOS‌：采用大圆角 (6px)、无边界选中状态（仅背景色+轻微轮廓）、SF Pro 字体栈。悬停效果柔和，强调内容的呼吸感。
Windows 11‌：采用小圆角 (4px)、明确的蓝色边框选中状态、Segoe UI Variable 字体。悬停效果清晰，强调结构的严谨性。深色模式下使用了特定的深灰色调而非纯黑。

分组与折叠交互‌：

定义了 .mac-group-header 和 .win-group-header，分别符合各自系统的标题栏样式（macOS 更简约，Windows 带有背景分隔）。
使用 CSS ::after 或 ::before 伪元素绘制折叠箭头，并通过 .collapsed 类控制旋转角度，实现纯 CSS 的视觉折叠状态切换（实际隐藏内容需配合 JS
 切换 .hidden 类）。

主题适配‌：

两套方案均使用 @media (prefers-color-scheme: dark) 自动切换深色模式变量，确保在系统主题变更时，文件视图的背景、文字、边框和选中色能无缝过渡。

可扩展性‌：

所有颜色、间距、字体均通过 CSS 变量 (:root) 定义，方便后续根据用户自定义强调色或布局偏好进行全局调整。


请根据历史对话中的全局设定，给出两套对应的CSS，用于指定'下拉菜单'的样式，包括单选和多选择菜单项的样式（若有）
===============================================================================
以下是基于 macOS 和 Windows 11 设计语言的下拉菜单（Dropdown/Select）样式 CSS。这两套方案分别模拟了各自系统在原生控件中的视觉表现，
包括触发按钮、下拉面板、选项项（含单选选中状态、多选复选框状态）、悬停效果以及分组样式。

1. macOS 风格下拉菜单 CSS

macOS 的下拉菜单通常表现为“弹出式菜单”（Pop-up Menu），具有显著的圆角、阴影，且选中项通常通过勾选标记（Checkmark）或高亮背景表示。
多选场景下（如自定义多选组件），会使用标准的系统复选框样式。

2. Windows 11 风格下拉菜单 CSS

Windows 11 的 Fluent Design 下拉菜单具有更方正的轮廓（小圆角）、清晰的边框，以及使用系统强调色（Accent Color）作为选中状态的背景或指示器。
多选通常通过明确的复选框控件实现。

代码实现功能与特点

系统级视觉还原‌：

macOS‌：使用了大圆角 (8px)、蓝色高亮悬停、以及对勾标记来指示选中状态。深色模式下适配了半透明模糊效果 (backdrop-filter) 和相应的灰度色彩。
Windows 11‌：使用了小圆角 (4px)、强调色左侧边条指示选中、以及标准的 Fluent 复选框样式。深色模式下使用了深灰色背景和亮色强调色。

交互状态完整‌：

包含了 hover（悬停）、active（激活/展开）、selected（选中）、disabled（禁用）等状态的样式定义。
触发按钮在展开状态下会与下拉面板无缝连接（Windows 11 风格去除了底部边框和圆角）。

单选与多选支持‌：

单选‌：通过 CSS 伪元素 ::before 实现了对勾或强调色条，无需额外 HTML 结构即可显示选中状态。
多选‌：提供了 .mac-checkbox 和 .win-checkbox 类，模拟了原生复选框的外观，支持选中后的颜色变化和内部对勾显示。

分组与分隔‌：

定义了 .mac-dropdown-group-label 和 .win-dropdown-group-label，用于在下拉菜单中对选项进行分类，符合系统原生设置菜单的布局习惯。
提供了 .mac-dropdown-divider 和 .win-dropdown-divider 用于视觉分隔不同组别或操作。

主题自适应‌：

两套方案均通过 @media (prefers-color-scheme: dark) 媒体查询自动适配系统的深色模式，确保在不同主题下都能保持良好的可读性和美观性。


之前给出的mac上按钮的鼠标悬停动画以及finder中按钮的鼠标悬停动画有缺失，能补全吗？
===============================================================================
基于 macOS 的设计规范，按钮和 Finder 工具栏图标的悬停动画核心在于‌微妙的背景过渡‌、‌阴影变化‌以及‌图标状态的反馈‌。macOS 强调“流畅”与“非侵入性”，
  因此动画曲线通常使用 ease-out 或自定义贝塞尔曲线，时长控制在 0.2s - 0.3s。

以下是补全后的 CSS，分为‌通用按钮悬停动画‌和 ‌Finder 风格工具栏按钮悬停动画‌两部分。

1. macOS 通用按钮悬停动画 (General Button Hover)

macOS 的标准按钮（Push Button）在悬停时，背景色会轻微变深（或变亮，取决于深色/浅色模式），并伴随轻微的阴影提升，给人一种“可点击”的浮起感。

关键动画细节说明

过渡曲线 (Transition Timing)‌：

使用了 cubic-bezier(0.25, 0.8, 0.25, 1)，这是 macOS 常用的“缓出”曲线，使动画开始时较快，结束时缓慢平滑，符合苹果的物理动效直觉。
对于简单的背景色变化，使用 ease 或 ease-out 即可。

阴影与层级 (Shadow & Elevation)‌：

普通按钮悬停时，box-shadow 略微扩大且变深，模拟按钮“浮起”靠近用户的感觉。
点击时 (:active)，transform: scale(0.98) 模拟物理按压的微小形变。

Finder 工具栏的特殊性‌：

Finder 的工具栏按钮通常没有边框，依靠‌背景色的出现‌来指示可交互性。
分段控件的选中项在浅色模式下是‌白色卡片‌浮在灰色轨道上，而在深色模式下是‌深灰色卡片‌浮在更深的轨道上，这与标准按钮的反色逻辑不同，需特别注意媒体查询中的适配。

深色模式适配‌：

所有悬停背景色在深色模式下都使用了 rgba(255, 255, 255, 0.x)，以确保在深色背景上有足够的对比度，同时保持半透明的质感。

将这些 CSS 补充到之前的方案中，即可完整还原 macOS 按钮和 Finder 工具栏的交互动效。
#-Skeleton- -End-
'''
