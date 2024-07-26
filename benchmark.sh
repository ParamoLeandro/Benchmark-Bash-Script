#Scritp benchmarck creado para pc Linux Debian creado para la ejecucion en terminal 
#Para la clase de arquitectura de maquinas 3 por / Leandro Paramo | Deborah Gutierrez | Christopher Bustamante

#!/bin/bash

# Definir la secuencia de escape ANSI para color rojo
rojo='\033[0;31m'
fin_color='\033[0m'  # Restablecer el color a su valor predeterminado

# Definir el tiempo total de ejecución en segundos
tiempo_total=60  # Ejecutar durante 60 segundos en total

# Definir el intervalo de muestra en segundos para las métricas de CPU/RAM
intervalo_muestra=5  # Mostrar métricas cada 5 segundos

# Número de iteraciones para cada benchmark (CPU y memoria)
num_iteraciones=3  # Realizar 3 iteraciones de cada benchmark

# Proceso para estimular el uso de CPU y RAM
estimular_recursos() {
    echo "Estimulando uso de recursos (CPU y RAM) durante la ejecución del benchmark..."
    local start_time=$(date +%s)
    local current_time

    while true; do
        current_time=$(date +%s)
        # Estimular uso de CPU con operaciones intensivas
        # Usar 'bc' para realizar cálculos repetidos en un bucle
        echo "scale=8000; 4*a(1)" | bc -l > /dev/null &

        # Estimular uso de RAM con creación y eliminación de datos temporales
        stress --vm-bytes 512M --vm-keep > /dev/null &

        # Detener el proceso de estimulación después de que haya transcurrido el tiempo total
        if [ $((current_time - start_time)) -ge $tiempo_total ]; then
            echo "Deteniendo estimulación de recursos..."
            pkill -f "bc -l"
            pkill -f "stress --vm-bytes"
            break
        fi

        sleep 1
    done
}

# Función para mostrar métricas de CPU y RAM
mostrar_metricas() {
    local tiempo_actual
    local cpu_uso
    local ram_uso
    local tiempo_transcurrido=0

    while [ "${tiempo_transcurrido}" -lt "${tiempo_total}" ]; do
        tiempo_actual=$(date +"%F %T")
        cpu_uso=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        ram_uso=$(free | grep Mem | awk '{printf("%.2f"), $3/$2 * 100}')

        echo "${tiempo_actual} - CPU: ${cpu_uso}% - RAM: ${ram_uso}%"

        tiempo_transcurrido=$((tiempo_transcurrido + intervalo_muestra))
        sleep "${intervalo_muestra}"
    done
}

# Función para generar el informe basado en las métricas recopiladas
generar_informe() {
    local cpu_categoria
    local ram_categoria

    # Determinar categoría de uso de CPU
    if [ $(echo "$cpu_uso < 25" | bc) -eq 1 ]; then
        cpu_categoria="bajo"
    elif [ $(echo "$cpu_uso < 51" | bc) -eq 1 ]; then
        cpu_categoria="medio alto"
    else
        cpu_categoria="alto"
    fi

    # Determinar categoría de uso de RAM
    if [ $(echo "$ram_uso < 25" | bc) -eq 1 ]; then
        ram_categoria="bajo"
    elif [ $(echo "$ram_uso < 51" | bc) -eq 1 ]; then
        ram_categoria="medio alto"
    else
        ram_categoria="alto"
    fi

    # Generar informe
    echo "Resumen de ejecución de Benchmark" > "informe_benchmark.txt"
    echo "---------------------------------" >> "informe_benchmark.txt"
    echo "Tiempo total de ejecución: ${tiempo_total} segundos" >> "informe_benchmark.txt"
    echo "---------------------------------" >> "informe_benchmark.txt"
    echo "Uso promedio de CPU: ${cpu_uso}%" >> "informe_benchmark.txt"
    echo "Categoría de uso de CPU: ${cpu_categoria}" >> "informe_benchmark.txt"
    echo "Uso promedio de RAM: ${ram_uso}%" >> "informe_benchmark.txt"
    echo "Categoría de uso de RAM: ${ram_categoria}" >> "informe_benchmark.txt"

    echo "Informe guardado en: informe_benchmark.txt"
}

# Ejecutar la función para estimular el uso de recursos en segundo plano
estimular_recursos &

# Ejecutar la función para mostrar métricas de CPU y RAM en segundo plano
mostrar_metricas &

# Esperar el tiempo total de ejecución antes de generar el informe
sleep "${tiempo_total}"

# Obtener el último valor de uso de CPU y RAM
cpu_uso=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
ram_uso=$(free | grep Mem | awk '{printf("%.2f"), $3/$2 * 100}')

# Generar el informe basado en las métricas recopiladas
generar_informe

echo -e "${rojo}Benchark completado.${fin_color}"
