resource "aws_codestarconnections_connection" "main" {
  name          = "${var.project_name}-${var.env}-connection"
  provider_type = "GitHub"
}
