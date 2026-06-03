group "default" {
  targets = ["admixboost"]
}

target "base" {
  context = "."
  tags = ["tale88/admixboost:v2.1.2", "tale88/admixboost:latest"]
}

target "admixboost" {
  inherits = ["base"]
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64"]
}
