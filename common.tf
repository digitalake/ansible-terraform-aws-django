resource "aws_key_pair" "this" {
  key_name   = "this-key"
  public_key = file(var.ssh_public_key_path)
}