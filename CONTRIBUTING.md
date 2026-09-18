# Contributing

Keep pull requests focused and reproducible. Do not commit environment files, secrets, generated build output, user data, unlicensed assets, or internal operations material.

Before opening a pull request, run:

```bash
forge fmt --check
forge build
forge test -vvv
```

Changes to contract behavior, EIP-712 fields, owner permissions, payment logic, or deployment documentation require an explicit explanation and tests where practical.
