name: Setup Remote Access

on:
  workflow_dispatch:
    inputs:
      auth_code:
        description: 'Chrome Remote Desktop Authorization Code'
        required: true

jobs:
  setup-remote-access:
    runs-on: windows-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set CRD_AUTH_CODE
      run: echo "CRD_AUTH_CODE=${{ github.event.inputs.auth_code }}" >> $env:GITHUB_ENV

    - name: Set CRD Command
      run: |
        $crdCommand = '"' + "${Env:PROGRAMFILES(X86)}\Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe" + '"' + " --code=`"${{ github.event.inputs.auth_code }}`" --redirect-url=`"https://remotedesktop.google.com/_/oauthredirect`" --name=$Env:COMPUTERNAME"
        echo "CRD_COMMAND=$crdCommand" >> $env:GITHUB_ENV
      shell: pwsh

    - name: Setup Chrome Remote Desktop
      shell: pwsh
      run: |
          & $PSScriptRoot/setup-crd.ps1
