#!/bin/bash
echo "=============================================="
echo " CONFIGURACAO DA VPS - JOGO DA VELHA ONLINE"
echo "=============================================="
echo ""

echo "[PASSO 1] Instalando Docker e Docker Compose..."
echo ""

sudo apt update -y
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo ""
echo "[PASSO 2] Docker instalado. Verificando..."
echo ""
docker --version
sudo docker-compose --version
echo ""

echo "[PASSO 3] Subindo Nakama + Postgres..."
echo ""
cd /opt/jogodavelha || exit 1

# Usa o docker-compose-prod.yml se existir, senao o docker-compose.yml
if [ -f docker-compose-prod.yml ]; then
  sudo docker-compose -f docker-compose-prod.yml up -d
else
  sudo docker-compose up -d
fi

echo ""
echo "[PASSO 4] Aguardando containers iniciarem..."
echo ""
sleep 15

echo "[PASSO 5] Status dos containers:"
echo ""
sudo docker ps
echo ""

echo "[PASSO 6] Testando se o Nakama responde na porta 7350..."
echo ""
curl -s http://127.0.0.1:7350/ > /dev/null && echo "  OK - Nakama respondendo na porta 7350" || echo "  ERRO - Nakama nao respondeu"
echo ""

echo "=============================================="
echo "    INSTALACAO CONCLUIDA!"
echo "=============================================="
echo ""
echo "Agora va ao PAINEL DA SUA VPS e libere estas portas"
echo "no FIREWALL / SECURITY LIST para INTERNET (0.0.0.0/0):"
echo ""
echo "  7349  (API HTTP)"
echo "  7350  (WebSocket - ESSENCIAL para o jogo)"
echo "  7351  (gRPC)"
echo ""
echo "Depois disso, instale o APK nos 2 celulares."
echo ""
