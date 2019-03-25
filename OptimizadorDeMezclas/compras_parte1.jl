#primera parte del algoritmo de compras 

### demo compras v3 

using CSV, DataFrames


#- en este archivo se guardan los inputs metidos por el usuario en forma de matrices y luego se corre el
#de optimización por producto 

# primero se llaman las matrices (deben estar en formato CSV ) y se convierten a matrices 

#se ponen los inputs ya en formato para entrar al programa 

#mukin = CSV.read("MUKIN.csv")
#mukin_basics = convert(Array{Float64,2},mukin)'  #
cmax = CSV.read("CMAX.csv")
Supper = convert(Array{Float64,2},cmax)' #
cmin = CSV.read("CMIN.csv")
Slower = convert(Array{Float64,2},cmin)'  #
precio = CSV.read("PRECIO.csv")
Cbasic = convert(Array{Float64,2},precio)'#
precio = convert(Array{Float64,2},precio)
basicos = CSV.read("BASICO.csv")
basicos = convert(Array{Any,2},basicos) # nombre y código 
#proveedor = CSV.read("PROVEEDORE.csv")
#proveedor = convert(Array{String,2},proveedor)
#proveedor11 = convert(Array{String,2},proveedor)
transporte = CSV.read("TRANSPORTE.csv")
Ctrans = convert(Array{Float64,2},transporte)  #
tasa = CSV.read("TASA.csv")
tasa = convert(Array,tasa)
tasa = tasa[1]
#volat = CSV.read("VOLAT.csv")
#volat = convert(Array{Float64,2},volat)'
#color = CSV.read("COLOR.csv")
#color = convert(Array{Float64,2},color)'
unidades_precio = CSV.read("UNIDADES PRECIO.csv")
unidades_precio = convert(Array{String,2}, unidades_precio)
fx_usd = CSV.read("FX USD MXN.csv")
fx_usd = convert(Array, fx_usd)
fx_usd = fx_usd[1]
fx_eur = CSV.read("FX USD EUR.csv")
fx_eur = convert(Array, fx_eur)
fx_eur = fx_eur[1]
unidades_cantidad = CSV.read("UNIDADES CANTIDADES.csv")
unidades_cantidad = convert(Array{String,2},unidades_cantidad)
ddp = CSV.read("DDP.csv")
ddp = convert(Array{Float64,2},ddp)'




#despues se llaman las bases de datos requeridas 

basics = CSV.read("info basicos.csv")
basics = convert(Array,basics)
basics_1 = convert(Array, basics)
restricciones = CSV.read("restricciones de basicos.csv")
restricciones = convert(Array, restricciones)
grupos = CSV.read("basicos por grupo.csv")
grupos = convert(Array{Any,2}, grupos)
formulaciones = CSV.read("formulaciones.csv")
formulaciones = convert(Array{Any,2},formulaciones)
#demanda = CSV.read("demanda.csv")
#demanda = convert(Array{Any,2},demanda)

#_________________________________________________________________________________________
#hacemos el respectivo cambio de unidades para que todo quede en USD/kg 

#primero del precio
    
for i = 1:length(unidades_precio)

    if unidades_precio[i] == "USD/kg"
        
    elseif unidades_precio[i] == "USD/GAL"
        
        indice_densidad = findfirst(basics[:,2],basicos[i,2])
        densidad = basics[indice_densidad,8]
        Cbasic[i] = Cbasic[i]/(3.78541*densidad)
        
    elseif unidades_precio[i] == "USD/L"
        
         indice_densidad = findfirst(basics[:,2],basicos[i,2])
        densidad = basics[indice_densidad,8]
        Cbasic[i] = Cbasic[i]/densidad
        
        
    elseif unidades_precio[i] == "MXN/L"
        indice_densidad = findfirst(basics[:,2],basicos[i,2])
        densidad = basics[indice_densidad,8]
        Cbasic[i] = (Cbasic[i]/densidad)*(1/fx_usd[1])
        
    elseif unidades_precio[i]== "MXN/GAL"
        
         indice_densidad = findfirst(basics[:,2],basicos[i,2])
         densidad = basics[indice_densidad,8]
        Cbasic[i] = Cbasic[i]*(1/fx_usd[1])*(1/3.78541)*(1/densidad)
        
    elseif unidades_precio[i] == "MXN/kg"
       
        
        indice_densidad = findfirst(basics[:,2],basicos[i,2])
         densidad = basics[indice_densidad,8]
        Cbasic[i] = Cbasic[i]/fx_usd[1]
       
        
    end
end
    

#ahora lo hacemos con las cantidades minimas y máximas ofrecidas por el proveedor 

for i = 1:length(unidades_cantidad)
    
    if unidades_cantidad[i] == "GAL"
        
        indice_densidad = findfirst(basics[:,2],basicos[i,2])
        densidad = basics[indice_densidad,8]
        Supper[i] = Supper[i]*3.78541*densidad
        Slower[i] = Slower[i]*3.78541*densidad
        
    elseif unidades_cantidad[i] == "L"
        
        indice_densidad = findfirst(basics[:,2],basicos[i,2])
        densidad = basics[indice_densidad,8]
        Supper[i] = Supper[i]*densidad
        Slower[i] = Slower[i]*densidad
        
    elseif unidades_cantidad[i] == "Kg"
        
        Supper[i] = Supper[i]
        Slower[i] = Slower[i]
        
    end
end

#por ultimo, tomamos en cuenta el costo financiero 
nss = 0
for i = 1:length(ddp)
    if ddp == 0 
    else
        Cbasic[i] = Cbasic[i]/(1+tasa[1]/365)^ddp[i]
    end
end 


#se identifica cuantas ofertas de básicos metió el usuario 
total_inputs = length(basicos[:,1])

#ahora hay que identificar que productos pueden ser mezclados utilizando estos básicos

productos_permitidos = Array{Any,1}(length(formulaciones[:,1]))
posible = Array{Int8,1}(length(basicos[:,1]))
contador = 0 

for i = 1:length(formulaciones[:,1])
    
    contador = contador + 1 
    
    z = formulaciones[i,3]
    z1 = string(z)
  

    #encontramos las restriccciones de básicos de este producto 
    y = findfirst(restricciones[:,1],z)
    y1 = restricciones[y,6:10]

    lg = length(grupos[:,1]) #nos indica cuantos basicos se pueden utilizar de acuerdo a las restricciones

    g = Array{Any,2}(lg,5) #se indica 5 porque es la cantidad de grupos posibles en el caso de haber mas o menos este numero debe cambiar

    #obtenemos los básicos especificados en la formulación 
    y2 = restricciones[y,2:5]
    fun(y2) = y2 == 0
    zero_elements = find(fun,y2)
    y3 = deleteat!(y2,zero_elements)

    #obtenemos todos los básicos permitidos para hacer este producto 
    nss = 0 
    for j = 1:5
        nss = nss+1
         if y1[j]==1 
            g[:,nss]=grupos[:,2*j]
        else 
            g[:,nss]= zeros(Int8,lg,1)
        end 
    end 
    
    #find the zero elements in the arrays and delete them 
    basico = Array{Any,1}(5)
    ns = 0
    for j = 1:5
        ns = ns+1
        x = g[:,j]
        fun(x) = x == 0
        zero_elements = find(fun,x)
        new_vector = deleteat!(g[:,j],zero_elements)
        basico[ns] = new_vector
    end

    #construimos un vector con todos los básicos permitidos para formar este producto
    b1 = append!(basico[1],basico[2])
    b2 = append!(b1,basico[3])
    b3 = append!(b2,basico[4])
    b4 = append!(b3,basico[5])
    

    #ahora vemos si los basicos ofrecidos por los proveedores estan dentro de los basicos permitido en el producto
    nss = 0  

    
    for j = 1:length(basicos[:,1])
            bas = basicos[j,2]
            se_puede = findfirst(b4,bas)
        
         if se_puede == 0
            nss = nss + 1 
            posible[nss] = 0 
         else 
            nss = nss + 1 
            posible[nss] = 1 
         end
    end 

    if sum(posible) == total_inputs 
      
        productos_permitidos[contador]=z
    else
       
        productos_permitidos[contador]=0
    end

end

#find zero elements in product array and delete them 

x = productos_permitidos 
fun(x) = x == 0
zero_elements = find(fun,x)
productos_permitidos = deleteat!(productos_permitidos,zero_elements)

#ya obtuvimos todos los productos que pueden ser mezclados usando los básicos que son ofrecidos
#_____________________________________________________________________________

#guardamos las variables para luego utilizarlas en la segunda parte del programa
Cbasic = reshape(Cbasic,total_inputs)
Cbasic = DataFrame(info = Cbasic)
CSV.write("Cbasic", Cbasic)

Supper = reshape(Supper,total_inputs)
Supper = DataFrame(info = Supper)
CSV.write("Supper", Supper)

Slower = reshape(Slower,total_inputs)
Slower = DataFrame(info = Slower)
CSV.write("Slower", Slower)

total_inputs = DataFrame(info = total_inputs)
CSV.write("total_inputs", total_inputs)

productos_permitidos = DataFrame(info = productos_permitidos)
CSV.write("productos_permitidos", productos_permitidos)