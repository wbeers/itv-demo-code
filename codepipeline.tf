resource "aws_codepipeline" "s3-pipeline" {
  artifact_store {
    location = aws_s3_bucket.s3-site.bucket
    type     = "S3"
  }

  name     = "${var.prefix}pipeline"
  role_arn = "arn:aws:iam::781196510485:role/service-role/AWSCodePipelineServiceRole-us-east-1-s3-static-pipeline"

  stage {
    action {
      category = "Source"

      configuration = {
        BranchName           = "main"
        ConnectionArn        = "arn:aws:codestar-connections:us-east-1:781196510485:connection/3c239c9d-392d-4257-9b23-df8fd6df2ea1"
        FullRepositoryId     = "wbeers/s3-static-site"
        OutputArtifactFormat = "CODE_ZIP"
      }

      name             = "Source"
      namespace        = "SourceVariables"
      output_artifacts = ["SourceArtifact"]
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      region           = "us-east-1"
      run_order        = "1"
      version          = "1"
    }

    name = "Source"
  }
  
    stage {
    action {
      category = "Deploy"

      configuration = {
        BucketName = aws_s3_bucket.s3-site.bucket
        Extract    = "true"
      }

      input_artifacts = ["SourceArtifact"]
      name            = "Deploy"
      namespace       = "DeployVariables"
      owner           = "AWS"
      provider        = "S3"
      region          = "us-east-1"
      run_order       = "1"
      version         = "1"
    }

    name = "Deploy"
  }

}
