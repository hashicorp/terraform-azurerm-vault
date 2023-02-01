# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

output "ca_public_key_file_path" {
  value = "${var.ca_public_key_file_path}"
}

output "public_key_file_path" {
  value = "${var.public_key_file_path}"
}

output "private_key_file_path" {
  value = "${var.private_key_file_path}"
}

