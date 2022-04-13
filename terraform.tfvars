aws-region        = "eu-west-2"
#Enter a valid profile here or set the ENV VARIABLES
#aws-profile       = "muawiakh-dev"
user-data-script  = "./scripts/ghost.sh"
#instance-key-name = "deployer-key"
instance-tag-name = "Ghost-Maker-instance"
# Please use a better way to store the password
sql-pass-host = "strongpassword"
instance-type = "t2.medium"
