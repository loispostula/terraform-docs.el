/**
 * terraform-docs.el:
 *
 * Example of 'test' module.
 */

terraform {
  required_version = ">= 0.12"
  required_providers {
    random = ">= 2.2.0"
  }
}
resource "null_resource" "foo" {}
