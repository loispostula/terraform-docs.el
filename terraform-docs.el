;;; terraform-docs.el --- Integrate terraform-docs with Emacs -*- lexical-binding: t; -*-

;; Author: Loïs Postula <lois@postu.la>
;; URL: https://github.com/loispostula/terraform-docs.el
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: terraform, tools, docs

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides integration with `terraform-docs` to generate
;; Terraform documentation directly from Emacs. You can display the output
;; in a buffer, save it to a file, or both.

;;; Code:

(defgroup terraform-docs nil
  "Integration of terraform-docs with Emacs."
  :group 'tools)


(defcustom terraform-docs-config-name ".terraform-docs.yml"
  "The name of the Terraform Docs configuration file."
  :type 'string
  :group 'terraform-docs)

(defun terraform-docs-config-file (start-dir)
  "Find the full path to the Terraform Docs configuration file
starting from START-DIR and searching upwards."
  (let ((config-dir (locate-dominating-file
                     start-dir
                     (lambda (dir)
                       (file-exists-p (expand-file-name terraform-docs-config-name dir))))))
    (when config-dir
      (expand-file-name terraform-docs-config-name config-dir))))

(defun terraform-docs (&optional file-path stdout)
  "Run terraform-docs.
If FILE-PATH is provided, use it as the base path.
   Otherwise, default to the current buffer.
If STDOUT is non-nil, return the output as a string
   instead of using the user-defined configuration."
  (let* ((file-path (or file-path (buffer-file-name)))
         (current-dir (file-name-directory file-path))
         (config-file (terraform-docs-config-file current-dir))
         (module-dir (or current-dir ""))
         (command (concat "terraform-docs"
                          (when config-file
                            (concat " -c " config-file))
                          (when stdout
                            " --output-file=\"\"")
                          " "
                          (expand-file-name module-dir))))
    (if command
        (progn
          (message "Running command: %s" command)
          (if stdout
              (with-output-to-string
                (shell-command command standard-output))
            (shell-command command)))
      (error "Error: %s not found in any parent directories" terraform-docs-config-name))))

(defun terraform-docs-to-buffer (&optional file-path)
  "Run terraform-docs and write the output to a temporary buffer.
If FILE-PATH is provided, use it as the base path.
    Otherwise, default to the current buffer."
  (interactive)
  (let ((output (terraform-docs file-path t)))
    (with-output-to-temp-buffer "*terraform-docs-output*"
      (princ output))))

(defun terraform-docs-to-file (&optional file-path file-name)
  "Run terraform-docs and write the output to a generated file.
The file name is based on the directory where terraform-docs is executed.
If FILE-PATH is provided, use it as the base path.
   Otherwise, default to the current buffer.
If FILE-NAME is provided, use it as the output path.
   Otherwise, generate it based on the directory
   where terraform-docs is executed."
  (interactive)
  (let* ((file-path (or file-path (buffer-file-name)))
         (current-dir (file-name-directory file-path))
         (directory-name (file-name-nondirectory (directory-file-name current-dir)))
         (output-file (or file-name (expand-file-name (format "output-for-%s.md" directory-name) current-dir)))
         (output (terraform-docs file-path t)))
    (with-temp-file output-file
      (insert output))
    (message "Output written to %s" output-file)
    output-file))

(defun terraform-docs-to-file-and-open (&optional file-path)
  "Run terraform-docs and write the output to a generated file and open it.
The file name is based on the directory where terraform-docs is executed.
If FILE-PATH is provided, use it as the base path.
   Otherwise, default to the current buffer.
If FILE-NAME is provided, use it as the output path.
   Otherwise, generate it based on the directory
   where terraform-docs is executed."
  (interactive)
  (let ((output-file (terraform-docs-to-file file-path)))
    (find-file output-file)))

(provide 'terraform-docs)

;;; terraform-docs.el ends here
