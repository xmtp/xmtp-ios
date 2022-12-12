FROM mcr.microsoft.com/devcontainers/typescript-node:16-bullseye
WORKDIR /code
ADD script.js script.js
RUN npm install @xmtp/xmtp-js ethers
CMD ["node", "script.js"]
