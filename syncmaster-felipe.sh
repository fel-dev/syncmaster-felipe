#!/bin/bash
# syncmaster-felipe.sh
# Painel interativo para delay e volume – por Felipe
# Licenciado sob a MIT License

# === CONFIGURAÇÃO INICIAL ===
headset_sink="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink"
bt_sink="bluez_output.13_68_0E_AF_02_6D.1"

mostrar_status () {
    vol1=$(pactl get-sink-volume "$headset_sink" | awk '{print $5}')
    vol2=$(pactl get-sink-volume "$bt_sink" | awk '{print $5}')
    delay1=$(pactl list short modules | grep "$headset_sink" | grep loopback | grep delay_hub.monitor | sed -E 's/.*latency_msec=([0-9]+).*/\1 ms/' | tail -n1)
    delay2=$(pactl list short modules | grep "$bt_sink" | grep loopback | grep delay_hub.monitor | sed -E 's/.*latency_msec=([0-9]+).*/\1 ms/' | tail -n1)
    delay1=${delay1:-"0 ms"}
    delay2=${delay2:-"0 ms"}

    echo ""
    echo "🎛️  Estado atual dos dispositivos de saída:"
    echo ""
    printf "%-60s | %-8s | %-6s\n" "Dispositivo" "Volume" "Delay"
    echo "---------------------------------------------------------------------------------------------"
    printf "%-60s | %-8s | %-6s\n" "Headset com fio (R7)" "$vol1" "$delay1"
    printf "%-60s | %-8s | %-6s\n" "Bluetooth (SM-21)"    "$vol2" "$delay2"
    echo ""
}

aplicar_delay () {
    read -p "Informe o delay em milissegundos (ou Enter para voltar): " delay
    [ -z "$delay" ] && return

    echo "🔄 Limpando módulos antigos..."
    pactl list short modules | grep 'source=delay_hub.monitor' | awk '{print $1}' | while read id; do pactl unload-module "$id"; done

    if [ "$dispositivo" = "1" ]; then
        echo "🎧 Aplicando delay de $delay ms no headset com fio (R7)"
        pactl load-module module-loopback source=delay_hub.monitor sink=$bt_sink latency_msec=0
        pactl load-module module-loopback source=delay_hub.monitor sink=$headset_sink latency_msec=$delay
    else
        echo "🎧 Aplicando delay de $delay ms no Bluetooth (SM-21)"
        pactl load-module module-loopback source=delay_hub.monitor sink=$headset_sink latency_msec=0
        pactl load-module module-loopback source=delay_hub.monitor sink=$bt_sink latency_msec=$delay
    fi
}

ajustar_volume () {
    read -p "Informe o volume (ex: 90%, +10%, -5%) ou Enter para voltar: " vol
    [ -z "$vol" ] && return

    if [ "$dispositivo" = "1" ]; then
        pactl set-sink-volume "$headset_sink" "$vol"
        echo "🔊 Volume do R7 ajustado para $vol"
    else
        pactl set-sink-volume "$bt_sink" "$vol"
        echo "🔊 Volume do SM-21 ajustado para $vol"
    fi
}

# === INÍCIO DO SCRIPT ===

clear
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 🔊 SyncMaster Felipe™ – Painel de Controle  "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mostrar_status

read -p "Escolha o dispositivo para controlar (1 = R7 | 2 = SM-21 | Enter para sair): " dispositivo
[ -z "$dispositivo" ] && echo "Saindo." && exit

while true; do
    echo ""
    echo "🧭 O que deseja fazer?"
    echo "[1] Ajustar delay"
    echo "[2] Ajustar volume"
    echo "[3] Mostrar status atual"
    echo "[4] Trocar de dispositivo"
    echo "[Enter] Sair"
    echo "---"
    echo "[l] Listar dispositivos disponíveis"
    read -p "Opção: " acao
    [ -z "$acao" ] && echo "Saindo." && break

    case "$acao" in
        1) aplicar_delay ;;
        2) ajustar_volume ;;
        3) mostrar_status ;;
        4) exec "$0" ;;  # Reinicia o script
        l)
        echo ""
        echo "🎧 Dispositivos de saída disponíveis:"
        pactl list short sinks | awk '{printf "[%s] %s\n", NR, $2}'
        echo ""
        ;;
        *) echo "❌ Opção inválida." ;;
    esac
done
