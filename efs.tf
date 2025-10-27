resource "aws_efs_access_point" "efs_ap_synapse" {
  file_system_id = var.efs_id

  root_directory {
    path = "/${local.task_name}/data"
    creation_info {
      owner_uid   = 991
      owner_gid   = 991
      permissions = "755"
    }
  }

  posix_user {
    # the user Fargate tasks will run as
    uid = 991
    gid = 991
  }

  tags = {
    Name = "${local.task_name}-efs-ap-synapse"
  }
}

resource "aws_efs_access_point" "efs_ap_cfgmgr" {
  file_system_id = var.efs_id

  root_directory {
    path = "/${local.task_name}/data"
    creation_info {
      owner_uid   = 0
      owner_gid   = 0
      permissions = "755"
    }
  }

  posix_user {
    # the user Fargate tasks will run as
    uid = 0
    gid = 0
  }

  tags = {
    Name = "${local.task_name}-efs-ap-cfgmgr"
  }
}

resource "aws_efs_access_point" "efs_ap_web" {
  file_system_id = var.efs_id

  root_directory {
    path = "/${local.task_name}/web/config"
    creation_info {
      owner_uid   = 0
      owner_gid   = 0
      permissions = "755"
    }
  }

  posix_user {
    # the user Fargate tasks will run as
    uid = 0
    gid = 0
  }

  tags = {
    Name = "${local.task_name}-efs-ap-web"
  }
}
