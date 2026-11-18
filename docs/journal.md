# Journal

Background: The idea here is human notes about what was done during the project that

## 11/14/2026

1. Manually set up AWS Account
2. Upon completion, I was given a prompt to give to the agent.
```
Set up Agent Toolkit for AWS by following instructions:
https://raw.githubusercontent.com/aws/agent-toolkit-for-aws/refs/heads/main/setup-instructions/setup.md

Your AWS Region is: us-east-2
AWS experience: The new AWS experience
```
3. Manually set up project, `Portfolio-2026-November`
4. Manually set up an AWS budget for $100/month
5. Via Prompt
```
What I did:

AWS CLI 2.40.3: installed. The serpentair profile signs in through aws login in us-east-2 and is verified. It runs as AccountFullAccessRole in account 900417081299.
uv: installed, because the MCP server needs it.
Agent Toolkit:
MCP entries: aws-mcp was added to ~/.claude.json and Cursor's mcp.json, both pointed at the serpentair profile. I backed up both files first (*.bak-awsmcp).
AWS skills: it also installed 25 AWS skills into your global ~/.claude/skills, so they'll show up in every project, not just this one.
AGENTS.md:
New "AWS access" section: names the profile and says the MCP and CLI are for reading state and docs only. All changes go through Terraform, and later CI. Since the role has full access, that rule is the only guard.
AWS starter rules: added below that, between the toolkit's markers. Your section comes first, and those rules say project instructions take precedence over them.
This isn't committed yet.
```
6. Restarted VS Code to pick up new `aws` CLI path.
7. Tested AWS CLI installation with `aws --version`
response:
```
aws-cli/2.40.3 Python/3.14.8 Windows/11 script-exe/AMD64
```
8. Tested AWS CLI Profile configuration with 
``
$ `aws sts get-caller-identity --profile serpentair`
response:
```
{                                                                     
    "UserId": "ARO...",
    "Account": "900...",
    "Arn": "arn:aws:sts::900...:assumed-role/AccountFullAccessRole/141..."
}
```
9. Re-oriented around next steps:
- Me: You sign up for 
- Airthings (API client), 
- Prefect Cloud
- dbt platform.
 I write a /wizard script that opens each page and saves the credentials into a git-ignored .env.
- Agent: (other things)
10. Airthings - Account and API Access
    - Go to the Airthings dashboard (consumer-api-doc.airthings.com/dashboard) and sign in with your normal Airthings account. It sends you to accounts.airthings.com.
    - Open My Applications and click Create New Application.
    ![alt text](image.png)
    - Give it a name (for example serpentair) and a short description. If you're asked for a flow type, pick the client credentials (machine-to-machine) option. The Lambda signs in as itself, not as you in a browser.
    - Copy the Client ID and Client Secret somewhere safe right away, such as a password manager. Don't put them in the repo or the journal. Later they'll go into .env, then AWS Secrets Manager.
11. Used Matt Pocock `/wizard` skill to capture ClientID and ClientSecret. 
- The Wizard skill generates a .sh file
- You run the .sh file
- It then walks you through visiting the right webpage, copy/pasting values, and then runs a test API call to validate you can authenticate - very nice
12. Manually set up dbt Account
- Ran wizard skill to get information into .env
13. Emporia Account
- Had an existing Emporia account
- Converted from social sign in to email/password
- Ran wizard skill to get information into .env and test access
```
  Installing PyEmVue in a throwaway environment (first run takes a moment)...
  ✓ logged in with email + password
  devices: 7
    - catpad gid=392825 model=SSO001 channels=1
    - Garage/Wreath gid=397064 model=SSO001 channels=1
    - Main Panel (200A) 11515 gid=625979 model=VUE003 channels=1
    - (unnamed) gid=625979 model=WAT001 channels=17
    - Dehumidifier gid=649871 model=SSO001 channels=1
    - Garage gid=668558 model=VUE003 channels=1
    - (unnamed) gid=668558 model=WAT001 channels=18
  today on 'catpad' channel 1,2,3: 24 hourly points, 24 non-empty, total 0.18 kWh (first point 2026-11-14 05:00:00+00:00)
  ✓ password login works
  ```
  - Main Panel and Garage are two Emporia Vue units
  - Other devices are smart outlets that monitor/enable specific appliances.

14. Prefect Account
- Made a Prefect account, Google social login
- $ `uvx prefect-cloud login`
    ```
        ✓ Logged in to Prefect Cloud
    ```
- $ `uvx prefect-cloud github setup`
    ```
    ✓ Prefect Cloud GitHub integration complete

    Connected repositories:
    - davidpickering/serpentair

    Deploy a function from your repo with:
    prefect-cloud deploy <file.py:function> --from <github repo>
    ```
- $ `uvx prefect work-pool create serpentair-managed --type prefect:managed`
```
Installed 105 packages in 3.57s
Created work pool 'serpentair-managed'!

└── UUID: 219ec96f-e425-4eea-b6e3-1cfeac12737f
└── Type: prefect:managed
└── Description: None
└── Status: Ready
└── URL: https://app.prefect.cloud/account/d4e05ffe-0cc3-43eb-bfa6-4913500ddcff/workspace/8fc2a4a6-d624-46db-a39e-58cb51e6762e/work-pools/work-pool/serpentair-managed
```

15. Next steps
> Next is #4 (Snowflake prod with cost safeguards, plus the Terraform bootstrap). This conversation is long, and #4 has everything it needs written down. So the flow says /clear now, then /mattpocock-skills:implement with #4. If you want to look back at this session first, run /retro before you clear, because it reviews the current conversation.

## 11/15/2026

1. Prompt `/mattpocock-skills:implement #4`git 
2. Manually made snowflake account
3. Config snowflake
- Retrieved `org name` and `account name`, `current user`
- Generated key
- altered user to apply RSA Key, private key allows programatic access from outside of Snowflake
- authenticated to aws from snowflake

4. Wizard Script
- Generated terraform bootstrap
- Generated terraform prod plan
- Installed dbt V2.0.11
- Established `.dbt/profiles.yml` for project serpentair - dbt_dpickering schema
- hello world version of `dbt build`
- Configured connection to Snowflake in dbt Platform

## 11/16/20206
1. Manual
- commited infra/bootstrap/keys/svc_terraform_ci.pub (bootstrap reads it on every plan, incl. CI)
- Ran `dbt debug` + `dbt build` in `transform/` - we have hello world!

## 11/17/2026
1. Worked on Pull Request description for #4. PR Review is a great place to check work and build understanding.
2. Had not encountered committing a public key to a repo before. Spent some time understanding that practice and why it was not problematic.
3. Examined Terraform work around the `infra/` directory. The main point of this portfolio project is to gain practical experience with Terraform. GenAI implementation - although impressive - took us from step 1 to 87 in 10 minutes. Kind of incredible, but not a great way for me to learn about it. Commented to this effect to the Claud Code with /ask-matt and came up with a plan for future tickets to just coach me through the Terraform authorship and criteria. Workflow lives at `docs/agents/terraform.md`
4. Ran a `/retro` session and surfaced some Agent/Human collaboration refinements
    - Getting terraform on my PATH. Done. `terraform version`
    - Coding standards for terraform
5. Next step: Review PR + Study Terraform code in the repo at a high level.