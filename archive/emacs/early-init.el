;; -*- lexical-binding: t; -*-

(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (expand-file-name "emacs/eln-cache/" (or (getenv "XDG_CACHE_HOME") "~/.cache/"))))

;; 彻底关闭 native compilation
(setq native-comp-jit-compilation nil)
(setq native-comp-deferred-compilation nil)
(setq native-comp-async-report-warnings-errors nil)

;;(setq native-comp-speed 3
;;      native-comp-deferred-compilation t
;;      package-native-compile t)
;;(setq warning-minimum-level :error)
;;(setq native-comp-jit-compilation-deny-list '(".*-loaddefs.el.gz"))
;;(setq completion-auto-help nil)

;;启动优化
(setq gc-cons-threshold (* 50 1000 1000))

;; 不加载 .elc，优先用 .el
(setq load-prefer-newer t)

;; 禁止生成 .elc（byte-compile）
(setq byte-compile-warnings nil)
(setq byte-compile-verbose nil)

;;启动界面
(setq inhibit-startup-screen t)
(setq initial-buffer-choice (lambda () (progn   (dired "~/")   )))

;;(add-hook 'emacs-startup-hook (lambda ()
;;                                (when (get-buffer "*scratch*")
;;                                  (kill-buffer "*scratch*"))))


;;隐藏message
;;(setq-default message-log-max nil)
;;(kill-buffer "*Messages*")

;; Keep installed packages and private runtime state outside the linked config.
(defvar my/emacs-state-directory
  (expand-file-name "emacs/" (or (getenv "XDG_STATE_HOME") "~/.local/state/")))
(make-directory my/emacs-state-directory t)
(setq package-user-dir
      (expand-file-name "emacs/elpa/" (or (getenv "XDG_DATA_HOME") "~/.local/share/")))
(setq savehist-file (expand-file-name "history" my/emacs-state-directory)
      save-place-file (expand-file-name "places" my/emacs-state-directory)
      recentf-save-file (expand-file-name "recentf" my/emacs-state-directory)
      url-history-file (expand-file-name "url-history" my/emacs-state-directory)
      org-id-locations-file (expand-file-name "org-id-locations" my/emacs-state-directory)
      bookmark-default-file (expand-file-name "bookmarks" my/emacs-state-directory)
      project-list-file (expand-file-name "projects" my/emacs-state-directory)
      tramp-persistency-file-name (expand-file-name "tramp" my/emacs-state-directory)
      url-configuration-directory (expand-file-name "url/" my/emacs-state-directory)
      transient-history-file (expand-file-name "transient/history.el" my/emacs-state-directory)
      transient-levels-file (expand-file-name "transient/levels.el" my/emacs-state-directory)
      transient-values-file (expand-file-name "transient/values.el" my/emacs-state-directory))
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'custom-theme-load-path (expand-file-name "lisp" user-emacs-directory))


;;;大文件优化
(setq-default bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)
(setq-default bidi-display-reordering nil)

(setq long-line-threshold 1000)
(setq large-hscroll-threshold 1000)
(setq syntax-wholeline-max 1000)

;;(global-so-long-mode 1)
;; (setq-default cursor-in-non-selected-windows nil)
;; (setq fast-but-imprecise-scrolling t)
