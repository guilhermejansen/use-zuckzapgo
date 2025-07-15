# 🤝 Contributing Guide - ZuckZapGo Private

Thank you for your interest in contributing to **ZuckZapGo Private**! This is a **commercial/proprietary** project by Setup Automatizado, so contributions follow a specific process.

## 📋 Contribution Process

### 🔐 Private/Commercial Project

This is a **closed commercial** project. Contributions are accepted only from:
- Developers authorized by Setup Automatizado
- Clients with valid commercial licenses
- Approved commercial partners

### 📞 How to Contribute

1. **Contact First**
   - Email: [contato@zuckzapgo.com](mailto:contato@zuckzapgo.com)
   - Describe your contribution proposal
   - Wait for approval before starting any work

2. **Contribution Agreement**
   - All contributions require NDA signature
   - Intellectual property transfer agreement
   - Confidentiality terms

## 🛠️ Technical Guidelines

### Code Standards

**Go (Backend)**
```go
// Use gofmt for formatting
// Follow Go conventions
// Document public functions
// Use linting with golangci-lint
```

**TypeScript/React (Frontend)**
```typescript
// Use Prettier for formatting
// ESLint for code quality
// Strict TypeScript typing
// Functional components with hooks
```

### Commits
```bash
# Commit format
feat: add new functionality X
fix: fix bug Y
docs: update documentation Z
refactor: refactor component W
test: add tests for V
```

### Pull Requests

1. **Branch Naming**
   ```
   feature/feature-name
   bugfix/bug-name
   hotfix/hotfix-name
   ```

2. **Requirements**
   - Updated unit tests
   - Updated documentation
   - Approved code review
   - Passing CI/CD

3. **PR Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation

   ## Checklist
   - [ ] Tests passing
   - [ ] Documentation updated
   - [ ] Code review requested
   ```

## 🧪 Testing

### Backend (Go)
```bash
# Run all tests
go test ./...

# Tests with coverage
go test -cover ./...

# Benchmark
go test -bench=.
```

### Frontend (Next.js)
```bash
# Unit tests
npm test

# E2E tests
npm run test:e2e

# Coverage
npm run test:coverage
```

## 📚 Documentation

### API Documentation
- Updated Swagger/OpenAPI
- Included usage examples
- Documented error codes

### Code Documentation
```go
// ExampleFunction demonstrates how to use functionality X
// Parameters:
//   - param1: parameter description
//   - param2: parameter description
// Returns:
//   - result: return description
//   - error: error if any
func ExampleFunction(param1 string, param2 int) (string, error) {
    // implementation
}
```

## 🔒 Security

### Vulnerability Reports
- **DO NOT** open public issues for vulnerabilities
- Contact: [contato@zuckzapgo.com](mailto:contato@zuckzapgo.com)
- Use PGP encryption if possible

### Security Checklist
- [ ] Input validation
- [ ] Data sanitization
- [ ] Proper authentication
- [ ] Verified authorization
- [ ] Audit logs
- [ ] No sensitive data leakage

## 📊 Performance

### Important Metrics
- API latency < 100ms
- Throughput > 1000 req/s
- Memory usage < 512MB
- CPU usage < 50%

### Profiling
```bash
# Go profiling
go tool pprof http://localhost:8080/debug/pprof/profile

# Memory profiling
go tool pprof http://localhost:8080/debug/pprof/heap
```

## 🚀 Deployment

### Development Environment
```bash
# Docker Compose
docker-compose up -d

# Local development
go run main.go
```

### Staging/Production
- Automated CI/CD via GitHub Actions
- Deploy only after approval
- Automatic rollback if needed

## 📝 Licensing

**IMPORTANT**: All contributions become property of Setup Automatizado under the terms of the proprietary commercial license.

### Before Contributing
1. Read and accept license terms
2. Sign the Contributor License Agreement (CLA)
3. Confirm you have the right to contribute the code

## 📞 Contact

### Technical Team
- **Lead Developer**: Guilherme Jansen
- **Email**: [contato@zuckzapgo.com](mailto:contato@zuckzapgo.com)
- **Website**: [https://zuckzapgo.com](https://zuckzapgo.com)

### Support
- **Issues**: Only for confirmed bugs
- **Features**: Discuss via email first
- **Questions**: [contato@zuckzapgo.com](mailto:contato@zuckzapgo.com)

## 🙏 Recognition

Authorized contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Official documentation

---

**© 2025 Setup Automatizado - All rights reserved**

*This document is subject to the terms of the ZuckZapGo Private proprietary commercial license.* 