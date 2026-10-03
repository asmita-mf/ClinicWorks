using '../main.bicep'

param projectName = 'clinicworks'
param environment = 'dev'
param regionCode = 'ci'
param instance = '002'
param location = 'Central India'
param postgresAdminUsername = 'clinicadmin'

param postgresAdminPassword = readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD')
