resource "digitalocean_droplet" "puzzle_massive" {
  name       = lower("puzzle-massive-${var.environment}")
  size       = var.legacy_droplet_size
  image      = "ubuntu-20-04-x64"
  region     = var.region
  vpc_uuid   = digitalocean_vpc.puzzle_massive.id
  ssh_keys   = var.developer_ssh_key_fingerprints
  tags       = [digitalocean_tag.fw_web.id, digitalocean_tag.fw_developer_ssh.id]
  depends_on = [digitalocean_spaces_bucket_object.puzzle_massive_dist_tar]

  # https://docs.digitalocean.com/products/droplets/how-to/provide-user-data/#retrieve-user-data
  # Can also debug this locally by using the Vagrantfile in the environment
  # directory.
  # Or ssh to the droplet and tail the cloud-init logs:
  # tail -f /var/log/cloud-init-output.log
  user_data = local_file.droplet_puzzle_massive_user_data.sensitive_content
}

# Write out the user_data script to the environment folder to help with
# debugging.
resource "local_file" "droplet_puzzle_massive_user_data" {
  filename = "${lower(var.environment)}/user_data.sh"
  # Hint that this script shouldn't be edited by the owner.
  file_permission = "0500"
  sensitive_content = join("\n", concat([
    "#!/usr/bin/env bash",
    "CHECKOUT_COMMIT=${var.checkout_commit}",
    "REPOSITORY_CLONE_URL=${var.repository_clone_url}",
    "DIST_TAR=puzzle-massive/${lower(var.environment)}/${var.artifact_dist_tar_gz}",
    "ARTIFACT_BUCKET=${var.artifacts_bucket_name}",
    "ARTIFACT_BUCKET_REGION=${var.artifacts_bucket_region}",

    "cat <<-'BIN_CHECKSUMS' > checksums",
    file("${lower(var.environment)}/.bin_checksums"),
    "BIN_CHECKSUMS",

    "cat <<-'ENV_CONTENT' > .env",
    local_file.dot_env.sensitive_content,
    "ENV_CONTENT",

    "cat <<-'HTPASSWD_CONTENT' > .htpasswd",
    file("${lower(var.environment)}/.htpasswd"),
    "HTPASSWD_CONTENT",

    "cat <<-'AWS_CREDENTIALS' > aws_credentials",
    local_file.aws_credentials.sensitive_content,
    "AWS_CREDENTIALS",

    "cat <<-'AWS_CONFIG' > aws_config",
    local_file.aws_config.content,
    "AWS_CONFIG",

    file("${lower(var.environment)}/droplet-setup.sh")
  ]))
}


resource "random_pet" "dot_env__NEW_PUZZLE_CONTRIB" {
  # Changes every month when deploying.
  length = 2
  keepers = {
    month = formatdate("YYYY/MM", timestamp())
  }
}

resource "local_file" "dot_env" {
  filename = "${lower(var.environment)}/.env"
  # Hint that this has been generated from a template and shouldn't be edited by the owner.
  file_permission = "0400"
  sensitive_content = templatefile("dot_env.tmpl", {
    dot_env__UNSPLASH_APPLICATION_ID                      = var.dot_env__UNSPLASH_APPLICATION_ID
    dot_env__UNSPLASH_APPLICATION_NAME                    = var.dot_env__UNSPLASH_APPLICATION_NAME
    dot_env__UNSPLASH_SECRET                              = var.dot_env__UNSPLASH_SECRET
    dot_env__NEW_PUZZLE_CONTRIB                           = random_pet.dot_env__NEW_PUZZLE_CONTRIB.id
    dot_env__SECURE_COOKIE_SECRET                         = var.dot_env__SECURE_COOKIE_SECRET
    dot_env__SUGGEST_IMAGE_LINK                           = var.dot_env__SUGGEST_IMAGE_LINK
    dot_env__SMTP_HOST                                    = var.dot_env__SMTP_HOST
    dot_env__SMTP_PORT                                    = var.dot_env__SMTP_PORT
    dot_env__SMTP_USER                                    = var.dot_env__SMTP_USER
    dot_env__SMTP_PASSWORD                                = var.dot_env__SMTP_PASSWORD
    dot_env__EMAIL_SENDER                                 = var.dot_env__EMAIL_SENDER
    dot_env__EMAIL_MODERATOR                              = var.dot_env__EMAIL_MODERATOR
    dot_env__AUTO_APPROVE_PUZZLES                         = var.dot_env__AUTO_APPROVE_PUZZLES
    dot_env__LOCAL_PUZZLE_RESOURCES                       = var.dot_env__LOCAL_PUZZLE_RESOURCES
    dot_env__CDN_BASE_URL                                 = var.dot_env__CDN_BASE_URL
    dot_env__PUZZLE_RESOURCES_BUCKET_REGION               = digitalocean_spaces_bucket.cdn.region
    dot_env__PUZZLE_RESOURCES_BUCKET_ENDPOINT_URL         = "https://${digitalocean_spaces_bucket.cdn.region}.digitaloceanspaces.com"
    dot_env__PUZZLE_RESOURCES_BUCKET                      = digitalocean_spaces_bucket.cdn.name
    dot_env__PUZZLE_RESOURCES_BUCKET_OBJECT_CACHE_CONTROL = var.dot_env__PUZZLE_RESOURCES_BUCKET_OBJECT_CACHE_CONTROL
    dot_env__PUZZLE_RULES                                 = var.dot_env__PUZZLE_RULES
    dot_env__PUZZLE_FEATURES                              = var.dot_env__PUZZLE_FEATURES
    dot_env__BLOCKEDPLAYER_EXPIRE_TIMEOUTS                = var.dot_env__BLOCKEDPLAYER_EXPIRE_TIMEOUTS
    dot_env__MINIMUM_PIECE_COUNT                          = var.dot_env__MINIMUM_PIECE_COUNT
    dot_env__MAXIMUM_PIECE_COUNT                          = var.dot_env__MAXIMUM_PIECE_COUNT
    dot_env__PUZZLE_PIECE_GROUPS                          = var.dot_env__PUZZLE_PIECE_GROUPS
    dot_env__ACTIVE_PUZZLES_IN_PIECE_GROUPS               = var.dot_env__ACTIVE_PUZZLES_IN_PIECE_GROUPS
    dot_env__MINIMUM_IN_QUEUE_PUZZLES_IN_PIECE_GROUPS     = var.dot_env__MINIMUM_IN_QUEUE_PUZZLES_IN_PIECE_GROUPS
    dot_env__MAX_POINT_COST_FOR_REBUILDING                = var.dot_env__MAX_POINT_COST_FOR_REBUILDING
    dot_env__MAX_POINT_COST_FOR_DELETING                  = var.dot_env__MAX_POINT_COST_FOR_DELETING
    dot_env__BID_COST_PER_PUZZLE                          = var.dot_env__BID_COST_PER_PUZZLE
    dot_env__POINT_COST_FOR_CHANGING_BIT                  = var.dot_env__POINT_COST_FOR_CHANGING_BIT
    dot_env__POINT_COST_FOR_CHANGING_NAME                 = var.dot_env__POINT_COST_FOR_CHANGING_NAME
    dot_env__NEW_USER_STARTING_POINTS                     = var.dot_env__NEW_USER_STARTING_POINTS
    dot_env__POINTS_CAP                                   = var.dot_env__POINTS_CAP
    dot_env__BIT_ICON_EXPIRATION                          = var.dot_env__BIT_ICON_EXPIRATION
    dot_env__PUBLISH_WORKER_COUNT                         = var.dot_env__PUBLISH_WORKER_COUNT
    dot_env__STREAM_WORKER_COUNT                          = var.dot_env__STREAM_WORKER_COUNT
    dot_env__DOMAIN_NAME                                  = var.dot_env__DOMAIN_NAME
    dot_env__SITE_TITLE                                   = var.dot_env__SITE_TITLE
    dot_env__HOME_PAGE_ROUTE                              = var.dot_env__HOME_PAGE_ROUTE
    dot_env__SOURCE_CODE_LINK                             = var.dot_env__SOURCE_CODE_LINK
    dot_env__M3                                           = var.dot_env__M3
  })
}
