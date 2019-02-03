#archivo para identificar si las bases de datos estan correctas para utilizar el algoritmo de optimización 
using CSV

basics = CSV.read("info basicos.csv")
basics = convert(Array,basics)
restricciones = CSV.read("restricciones de basicos.csv")
restricciones = convert(Array, restricciones)
grupos = CSV.read("basicos por grupo.csv")
grupos = convert(Array{Any,2}, grupos)
formulaciones = CSV.read("formulaciones.csv")
formulaciones = convert(Array{Any,2},formulaciones)
demanda = CSV.read("demanda.csv")
demanda = convert(Array{Any,2},demanda)

#identificamos si todos los codigos en la DDBB de formulaciones estan en la DDBB de restricciones 

for i = 1:length(formulaciones[:,3])
    indice = findfirst(restricciones[:,1], formulaciones[i,3])
 
    if indice == 0 
        println("No se encontró el código de producto ", formulaciones[i,3], " en la DDBB de restricciones" )
    else 
    end
end

#ahora identificamos si los basicos especificados en las formulaciones estan en la base de datos de los basicos 

for i = 1:length(formulaciones[:,3])
    indice1 = findfirst(basics[:,2], formulaciones[i,5])
    indice2 = findfirst(basics[:,2], formulaciones[i,8])
    if indice1 == 0 
        println("No se encontro el primer basico del producto ", formulaciones[i,3], " en la DDBB de basicos")
    else
    end

    if indice2 == 0 
        println("No se encontro el segundo basico del producto", formulaciones[i,3], " en la DDBB de basicos")
    end 
end 

#identificamos si los basicos especificados en la DDBB de restricciones estan en la base de datos de los basicos 

for i = 1:length(restricciones[:,1])
    if restricciones[i,2] == 0 
    else
        indice1 = findfirst(basics[:,2], restricciones[i,2])
        if indice1 == 0 
            println("no se encuentra el 1er basico del producto ", restricciones[i,1], " de la DDBB de restricciones en la DDBB de basicos")
        else 
        end 
        end 
    if restricciones[i,3] == 0 
    else
        indice2 = findfirst(basics[:,2], restricciones[i,3])
        if indice2 == 0 
            println("no se encuentra el 2do basico del producto ", restricciones[i,1], " de la DDBB de restricciones en la DDBB de basicos")
        else 
        end

    end 
    if restricciones[i,4] == 0 
    else 
        indice3 = findfirst(basics[:,2], restricciones[i,4])
        if indice3 == 0 
            println("no se encuentra el 3er basico del producto ", restricciones[i,1], " de la DDBB de restricciones en la DDBB de basicos")
        else 
        end
    end

end

#revisamos ahora que los basicos en la DDBB de basicos se encuentren clasificados por grupo en la DDBB de "basicos por grupo" 

for i = 1:length(basics[:,1])
    indice1 = findfirst(grupos[:,2],basics[i,2])
    
    if indice1 == 0 
        indice2 = findfirst(grupos[:,4], basics[i,2])

        if indice2 == 0 
            indice3 = findfirst(grupos[:,6], basics[i,2])

            if indice3 == 0 
                indice4 = findfirst(grupos[:,8], basics[i,2])

                if indice4 == 0 
                    indice5 = findfirst(grupos[:,10], basics[i,2])

                    if indice5 == 0 

                        println("no se encontro el basico ", basics[i,2], " en ningun grupo de la DDBB 'basicos por grupo'")

                    else 
                    end
                else
                end 
            else
            end
        else
        end
    else
    end
end

#por ultimo, revisamos si hay productos para los cuales tenemos demanda que no se encuentran en la DDBB de formulaciones

for i = 1:length(demanda[:,1])
    indice = findfirst(formulaciones[:,3], demanda[i,1] )

    if indice == 0 

        println("No se encontro la formulación para el producto ", demanda[i,1], " en la DDBB de 'formulaciones'")
    end 
end 

