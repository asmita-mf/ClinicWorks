using '../main.bicep'

param projectName = 'clinicworks'
param environment = 'dev'
param regionCode = 'ci'
param instance = '002'
param location = 'Central India'
param postgresAdminUsername = 'clinicadmin'
param keyVaultOfficerUserObjectId = '84e5cc54-6a42-4482-ba66-ccad728a3ffb'

param postgresAdminPassword = readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD')
