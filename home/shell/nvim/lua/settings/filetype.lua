-- filetype
-- 只保留与内置探测不同的项: vim.filetype.add 的用户表会按名覆盖内置的
-- 函数型内容探测(如 .ts 的 Qt XML→xml, .cfg 的 RAPID→rapid), 与内置同结果的
-- 扩展名(py/rs/c/cpp/…)写进来没有任何收益, 反而丢掉内容判定。

-- .tex 内置默认判为 plaintex; 声明 LaTeX 偏好(内置开关, 见 :h ft-tex-plugin),
-- 内容为 ConTeXt 的 .tex 仍会被识别为 context
vim.g.tex_flavor = 'latex'

vim.filetype.add({
    extension = {
        -- scm / guile 用带点子类型: guile_ls 只在 scheme.guile 上启动(通用的 scheme 设置仍会加载)
        scm = 'scheme.guile',
        guile = 'scheme.guile',
    },
})
