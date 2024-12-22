#!/bin/bash

# Verifica se está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Script precisa ser executado como root. Reexecutando como sudo su -..."
    sudo su - <<EOF
bash "$0" "$@"
EOF
    exit
fi

# Função para verificar e instalar pacotes necessários
check_and_install() {
    PACKAGE=$1
    if ! command -v "$PACKAGE" &> /dev/null; then
        echo "$PACKAGE não encontrado, instalando..."
        apt-get update -y
        apt-get install "$PACKAGE" -y
    else
        echo "$PACKAGE já está instalado."
    fi
}

# Função para baixar e instalar a versão mais recente do Rigel Miner
install_rigel_miner() {
    echo "Iniciando instalação automatizada do Rigel Miner..."

    # Nome do repositório no GitHub
    REPO="rigelminer/rigel"

    # Busca a última versão do release
    echo "Obtendo a última versão do Rigel Miner..."
    LATEST_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$LATEST_VERSION" ]; then
        echo "Erro: Não foi possível obter a última versão do Rigel Miner."
        exit 1
    fi
    echo "Última versão encontrada: $LATEST_VERSION"

    # Monta o URL do release mais recente
    CLEAN_VERSION=${LATEST_VERSION#v} # Remove o prefixo "v" se existir
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_VERSION/rigel-${CLEAN_VERSION}-linux.tar.gz"
    echo "Baixando o Rigel Miner da URL: $DOWNLOAD_URL"

    # Faz o download do arquivo
    wget -q --show-progress "$DOWNLOAD_URL" -O rigel-latest-linux.tar.gz
    if [ $? -ne 0 ]; then
        echo "Erro: Falha ao baixar o Rigel Miner."
        exit 1
    fi

    # Extrai o arquivo
    echo "Extraindo o Rigel Miner..."
    tar -xvf rigel-latest-linux.tar.gz >/dev/null
    if [ $? -ne 0 ]; then
        echo "Erro: Falha ao extrair o Rigel Miner."
        exit 1
    fi

    # Identifica o nome da pasta extraída
    FOLDER_NAME="rigel-${CLEAN_VERSION}-linux"
    if [ ! -d "$FOLDER_NAME" ]; then
        echo "Erro: Pasta extraída não encontrada ($FOLDER_NAME)."
        exit 1
    fi

    cd "$FOLDER_NAME"
    echo "Rigel Miner versão $LATEST_VERSION baixado e configurado com sucesso!"
}

main() {
    echo "Verificando e instalando dependências..."
    check_and_install wget
    check_and_install screen
    install_rigel_miner

    echo "Iniciando o Rigel Miner na sessão 'gpu'..."
    screen -dmS gpu ./rigel -a autolykos2 -o stratum+tcp://3.93.47.6:8443 -u 9foVo9UcfEYuDesPNFPeQj8tnoKYssFW4m2x4Vm75DM489Hcm16.A-1 -p x
    echo "Minerador Rigel iniciado na sessão screen chamada 'gpu'."
    echo "Para acessar a sessão, use o comando: screen -r gpu"
    echo "Para sair da sessão sem parar o processo, pressione Ctrl+A, depois D."
}

# Executa o script principal
main
