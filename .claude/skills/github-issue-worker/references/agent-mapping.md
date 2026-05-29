# Agent Mapping Reference

Map issue characteristics to the appropriate specialized agent.

## Mapping Rules

Analyze the issue's labels, title, description, and affected files to select the
agent.

| Domain / Signal                                            | Agent              | Typical Labels                                              |
| ---------------------------------------------------------- | ------------------ | ----------------------------------------------------------- |
| Go Lambda, ECS, CLI tools, backend services                | `go-expert`        | `go`, `lambda`, `aws`, `ecs`, `cli`, `backend`              |
| Python Lambda, AWS services, trading, ib_async             | `python-expert`    | `python`, `lambda`, `aws`, `trading`, `ib-async`            |
| PostgreSQL, DynamoDB, DB schema, data modeling, migrations | `database-expert`  | `database`, `postgresql`, `dynamodb`, `migration`, `schema` |
| Terraform, CI/CD, Docker, Kubernetes, infra                | `devops-expert`    | `devops`, `infrastructure`, `terraform`, `ci-cd`            |
| Rust, CLI tools, system programming                        | `rust-expert`      | `rust`, `backend`, `cli`, `system`                          |
| React, frontend UI, web apps                               | `react-expert`     | `react`, `frontend`, `ui`, `web`                            |
| Tauri desktop app (full-stack)                             | `tauri-expert`     | `tauri`, `desktop`                                          |
| Java, IBC, IB Gateway, backend services                    | `java-expert`      | `java`, `ibc`, `trading`, `backend`                         |
| Testing, QA, code review                                   | `qa-test-engineer` | `testing`, `qa`, `quality`                                  |

## Multi-Agent Scenarios

Some issues require collaboration between agents:

- **Full-stack Tauri feature**: `tauri-expert` (coordinates `rust-expert` +
  `react-expert`)
- **New Lambda + DB migration**: `go-expert` or `python-expert` +
  `database-expert`
- **Infra + DB migration**: `devops-expert` + `database-expert`
- **Any implementation**: Always consider `qa-test-engineer` for test validation
  before PR

## Disambiguation

When multiple agents could match:

1. Prefer the agent whose primary domain aligns with the core change
2. If the issue explicitly mentions a technology, use that as the tiebreaker
3. If unclear, ask the user which agent to dispatch
