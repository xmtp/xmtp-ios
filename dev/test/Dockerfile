FROM mcr.microsoft.com/devcontainers/typescript-node:16-bullseye
WORKDIR /code
ADD dev/test/script.js script.js
RUN npm install @xmtp/xmtp-js ethers
CMD ["node", "script.js"]
