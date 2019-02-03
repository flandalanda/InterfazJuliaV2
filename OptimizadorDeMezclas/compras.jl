#demo compras v3 

using JuMP, AmplNLWriter, CoinOptServices, CSV, DataFrames, Plots

#- en este archivo se guardan los inputs metidos por el usuario en forma de matrices y luego se corre el
#de optimización por producto 

# primero se llaman las matrices (deben estar en formato CSV ) y se convierten a matrices 

#se ponen los inputs ya en formato para entrar al programa 

mukin = CSV.read("MUKIN.csv")
mukin_basics = convert(Array{Float64,2},mukin)'  #
cmax = CSV.read("CMAX.csv")
Supper = convert(Array{Float64,2},cmax)' #
cmin = CSV.read("CMIN.csv")
Slower = convert(Array{Float64,2},cmin)'  #
precio = CSV.read("PRECIO.csv")
Cbasic = convert(Array{Float64,2},precio)'  #
basicos = CSV.read("BASICO.csv")
basicos = convert(Array{Any,2},basicos) # nombre y código 
proveedor = CSV.read("PROVEEDORE.csv")
proveedor = convert(Array{String,2},proveedor)
proveedor11 = convert(Array{String,2},proveedor)
transporte = CSV.read("TRANSPORTE.csv")
Ctrans = convert(Array{Float64,2},transporte)  #
credito = CSV.read("CREDITO.csv")
credito = convert(Array{Float64,2},credito)'
tasa = CSV.read("TASA.csv") #esta será la inflación con la que se traerá a valor presente el costo del producto 
tasa = convert(Array{Float64,2},tasa)'
tasa = tasa[1]
volat = CSV.read("VOLAT.csv")
volat = convert(Array{Float64,2},volat)'
color = CSV.read("COLOR.csv")
color = convert(Array{Float64,2},color)'
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
dd_pago = CSV.read("dias de pago.csv")
dd_pago = convert(Array{Float64,2},dd_pago)


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
demanda = CSV.read("demanda.csv")
demanda = convert(Array{Any,2},demanda)

#_________________________________________________________________________________________
#hacemos el respectivo cambio de unidades para que todo quede en USD/kg 

#primero del precio
nss = 0 
for j = 1:length(precio)
    nss = nss + 1
    precio = precio[1]
    precio[nss] = precio[j]
end 
    
    
for i = 1:length(unidades_precio)

    if unidades_precio[i] == "USD/kg"
        
    elseif unidades_precio[i] == "USD/GAL"
        
        indice_densidad = findfirst(basics[:,2],basicos[i,2])
        densidad = basics[indice_densidad,8]
       
        Cbasic[i] = Cbasic[i]/(3.78541*densidad)
        println(Cbasic[i])
    elseif unidades_precio[i] == "USD/L"
        
         indice_densidad = findfirst(basics[:,2],basicos[i,2])
        densidad = basics[indice_densidad,8]
        Cbasic[i] = Cbasic[i]/densidad
        
        
    elseif unidades_precio[i] == "MXN/L"
        indice_densidad = findfirst(basics[:,2],basicos[i,2])
        densidad = basics[indice_densidad,8]
        
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
    nss = nss + 1
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

#sacamos el costo de los basicos contemplando el peso financiero 
for i = 1:length(dd_pago)
    if dd_pago[i]== 0 
        Cbasic[i] = Cbasic[i]
    else 
        Cbasic[i] = Cbasic[i]/(1+(tasa/100)/365)^dd_pago[i]
    end
end


#___________________________________________________________________________________________-
#indicamos que oferta sería escogida sin tener el algoritmo 


println("indique que oferta escogería normalmente: ")
oferta_escogida = parse(Int32,readline(STDIN))


#____________________________________________________________________________________________

#se identifica cuantas ofertas de básicos metió el usuario 
total_inputs = length(basicos[:,1])

#ahora hay que identificar que productos pueden ser mezclados utilizando estos básicos

# 


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
#indica el usuario cuantos productos quiere analizar 
#este será un input del GUI muchachos 
print("el total de los productos que se pueden mezclar con las ofertas son  ", length(productos_permitidos))
println("  indique cuantos productos desea analizar")
p_analizados = parse(Int32,readline(STDIN))

if p_analizados == 0 
    
else
    #__________________________________________________________________________________________


    #ahora encontramos la demanda de estos productos 

    indice = Array{Int8,1}(length(productos_permitidos))
    nss = 0 
    for i = 1:length(productos_permitidos)
        nss = nss + 1
        indice[nss] = findfirst(demanda[:,1],productos_permitidos[i])
    end 
    #construimos el vector de producto-demanda
    demanda1 = Array{Any,2}(length(productos_permitidos),2)
    nss = 0 
    for i = 1:length(productos_permitidos)
        nss = nss + 1 
        if indice[i] != 0
            demanda1[nss,1] = demanda[indice[i],1]
            demanda1[nss,2] = demanda[indice[i],2]
        else 
        end 
    end 

    demanda = sortrows(demanda1, by = x-> x[2], rev=true)



    #_____________________________________________________________________________________________
    #ahora extraemos la información de los básicos que están siendo ofrecidos y acomodamos la información
    # identificamos si se tiene el color y volatilidad como input 
    # en el caso de que no se tenga se extrae 

    for i = 1:length(basicos[:,2])
        if color[i]== -1 
        
        #en el caso de que no se tenga como input, entonces se busca en la base de datos de basicos
        indice = findfirst(basics[:,2],basicos[i,2])    
        color[i]= basics[indice,6]
        
        else 
        color[i] = color[i]      
        end 
        if volat[i] == -1 
        indice = findfirst(basics[:,2],basicos[i,2])
        volat[i] = basics[indice, 7]
        else 
        volat[i] = volat[i]
        end 
    end

    #extraemos también las viscosidades dinámicas de estos básicos a todas las temperaturas de ccs

    visc_dyn_bas = Array{Any,1}(length(basicos[:,2]))
    nss = 0 
    for i = 1:length(basicos[:,2])
        nss = nss + 1 
        indice = findfirst(basics[:,2],basicos[i,2])
        visc_dyn_bas[nss] = basics[indice,9:14]
    end 


    #________________________________________________________________________________
    #eliminamos de la lista de básicos para simular mezclas aquellos que se estan ofreciendo al usuario 

    #identificamos los básicos ofrecidos y eliminamos los códigos que se repiten 
    basics_codes = unique(basicos[:,2])


    #encontramos los básicos en la lista de básicos que simulan la mezcla y los eliminamos 
    indice = Array{Int32,1}(length(basics_codes))
    nss = 0 
    for i = 1:length(basics_codes)
        nss = nss + 1 
        indice = findfirst(basics[:,2], basics_codes[i])
        basics =  basics[setdiff(1:end,indice),:]   
    end

    #__________________________________________________________________________________
    #acomodamos los inputs de los básicos con los que se simulará la mezcla 
    #llamaremos al proveedor de estos básicos virtuales P1 

    #cantidad máxima: no hay tope superior
    cmax_p1 = fill(1e8,length(basics[:,1]))

    # cantidad mínima: no hay tope inferior
    cmin_p1 = fill(0, length(basics[:,1]))

    #les agregamos costo de transporte estandar y dias de pago = 0 
    ctrans_p1 = fill(0.11, length(basics[:,1]))
    dd_pago_p1 = fill(0,length(basics[:,1]))

    # viscosidad cinemática, color, volatilidad, viscosidad dinámica a todas las temperaturas y costo 
    visc_kin_p1 = Array{Float64,1}(length(basics[:,1]))
    color_p1 = Array{Float64,1}(length(basics[:,1]))
    volat_p1 = Array{Float64,1}(length(basics[:,1]))
    visc_dyn_p1 = Array{Any,1}(length(basics[:,1]))
    cbasic_p1 = Array{Float64,1}(length(basics[:,1]))
    proveedor_p1 = Array{Any,1}(length(basics[:,1]))
    nss = 0
    
    for i = 1:length(basics[:,1])
        nss = nss + 1 
        visc_kin_p1[nss] = basics[i,3]
        color_p1[nss] = basics[i,6]
        volat_p1[nss] = basics[i,7]
        visc_dyn_p1[nss] = basics[i, 9:14]
        cbasic_p1[nss] = basics[i,15]
        proveedor_p1[nss] = "p1"
    end 

 
    #__________________________________________________________________________________________
    #acomodamos los inputs que serán iguales para todos los productos analizados 

    #convertimos los inputs del usuario a vectores 
    mukin_basics = vec(mukin_basics)
    Supper = vec(Supper)
    Slower = vec(Slower)
    Cbasic = vec(Cbasic)
    Ctrans = vec(Ctrans)
    volat = vec(volat)
    color = vec(color)
    proveedor = vec(proveedor)
    dd_pago = vec(dd_pago)
    #agregamos los inputs del proveedor 1 

    mukin_basics = append!(mukin_basics,visc_kin_p1)'
    Supper = append!(Supper,cmax_p1)'
    Slower = append!(Slower,cmin_p1)'
    Cbasic = append!(Cbasic, cbasic_p1*1.5)'
    Ctrans = append!(Ctrans,ctrans_p1)'
    volatility_basics = append!(volat, volat_p1)'
    color_basics = append!(color, color_p1)'
    codigo_basics = append!(basicos[:,2], basics[:,2])
    proveedor = append!(proveedor,proveedor_p1)
    dd_pago = append!(dd_pago, dd_pago_p1)
    #__________________________________________________________________________________________________


    #creamos los arreglos donde guardaremos los resultados 

    new_cost1  = Array{Any,1}(p_analizados)
    new_basics1 = Array{Any,1}(p_analizados)
    new_code1 = Array{Any,1}(p_analizados)
    new_proveedor1 = Array{Any,1}(p_analizados)
    Z_optim1 = Array{Any,1}(p_analizados)
    porcentaje_ahorro = Array{Any,1}(p_analizados)
    demand_1 = Array{Any,1}(p_analizados)
    x1x2 = Array{Any,1}(p_analizados)
    basico_escogido = Array{Any,1}(p_analizados)
    
    col_opt = Array{Any,1}(p_analizados)
    vol_opt = Array{Any,1}(p_analizados)
    mudyn_opt = Array{Any,1}(p_analizados)
    col_form =Array{Any,1}(p_analizados) 
    vol_form = Array{Any,1}(p_analizados)
    mudyn_form = Array{Any,1}(p_analizados)
    mukin_form = Array{Any,1}(p_analizados)
    
    new_basicsx1 = Array{Any,1}(p_analizados)
    new_basicsx2 = Array{Any,1}(p_analizados)
    new_costx1 = Array{Any,1}(p_analizados)
    new_costx2 = Array{Any,1}(p_analizados)
    new_codex1 = Array{Any,1}(p_analizados)
    new_codex2 = Array{Any,1}(p_analizados)
    new_proveedorx1 = Array{Any,1}(p_analizados)
    new_proveedorx2 = Array{Any,1}(p_analizados)
    ahorro_ponderado = Array{Any,1}(p_analizados)
    ######################3
    dif_cost = Array{Any,1}(p_analizados)
    volat_nonopt = Array{Any,1}(p_analizados)
    color_nonopt = Array{Any,1}(p_analizados)
    vdyn_nonopt = Array{Any,1}(p_analizados)
    mukin_basopt = Array{Any,1}(p_analizados)
    x1x2_basopt = Array{Any,1}(p_analizados)
    x1x2_nonopt = Array{Any,1}(p_analizados)
    mukin_nonopt = Array{Any,1}(p_analizados)
    
           
    #__________________________________________________________________________________________________

    #inicia algoritmo por producto 

    #identificamos el producto a analizar 
    contador = 0 
    for v = 1:p_analizados 
        producto_codigo = demanda[v,1]
        
        indice = findfirst(formulaciones[:,3], producto_codigo)
        product = formulaciones[indice,:]
        
        #=_______________________________________________________________________________________
        calculamos cuanto hubiera costado el producto si no se usara el algoritmo 
        =#
        
        B1 = product[5]
        B2 = product[8]

        #identificamos las viscosidades y demás propiedades de los básicos utilizados por fórmula
        indice_B1 = findfirst(basics_1[:,2],B1)
        indice_B2 = findfirst(basics_1[:,2],B2)
        visc_B1 = basics_1[indice_B1,3]
        visc_B2 = basics_1[indice_B2,3]
        volat_B1 = basics_1[indice_B1,7]
        volat_B2 = basics_1[indice_B2,7]
        color_B1 = basics_1[indice_B1,6]
        color_B2 = basics_1[indice_B2,6]
        cost_B1 = basics_1[indice_B1,15]
        cost_B2 = basics_1[indice_B2,15]


        #identificamos la propiedades del básico escogido por el usuario
        B_usercode = basicos[oferta_escogida,2]
        B_user_indice = findfirst(basics_1[:,2],B_usercode)
        visc_Buser = basics_1[B_user_indice,3]
        cost_Buser = basics_1[B_user_indice,15]
        volat_Buser = basics_1[B_user_indice,7]
        color_Buser = basics_1[B_user_indice,6]
      
        
        if product[11]==0
            viscdyn_Buser = 0 
        else
        
            if product[11] == -10 
                viscdyn_Buser = basics_1[B_user_indice,9]
                viscdyn_B1 = basics_1[indice_B1,9]
                viscdyn_B2 = basics_1[indice_B2,9]
            elseif product[11] == -15
                viscdyn_Buser = basics_1[B_user_indice,10]
                viscdyn_B1 = basics_1[indice_B1,10]
                viscdyn_B2 = basics_1[indice_B2,10]
            elseif product[11] == -20
                viscdyn_Buser = basics_1[B_user_indice,11]
                viscdyn_B1 = basics_1[indice_B1,11]
                viscdyn_B2 = basics_1[indice_B2,11]
            elseif product[11] == -25
                viscdyn_Buser = basics_1[B_user_indice,12]
                viscdyn_B1 = basics_1[indice_B1,12]
                viscdyn_B2 = basics_1[indice_B2,12]
            elseif product[11] == -30  
                viscdyn_Buser = basics_1[B_user_indice,13]
                viscdyn_B1 = basics_1[indice_B1,13]
                viscdyn_B2 = basics_1[indice_B2,13]
            elseif product[11] == -35
                viscdyn_Buser = basics_1[B_user_indice,14]
                viscdyn_B1 = basics_1[indice_B1,14]
                viscdyn_B2 = basics_1[indice_B2,14]
            end
        end
  
        #obtenemos la diferencia entre la viscosidad del básico escogido y los básicos de la formulación
        #se sustituye aquel con el que tenga menor diferencia 
        B_diff1 = abs(visc_B1-visc_Buser)
        B_diff2 = abs(visc_B2-visc_Buser)
        if B_diff1 > B_diff2
            B2 = B_usercode
            visc_B2 = visc_Buser
            cost_B2 = cost_Buser 
            volat_B2 = volat_Buser
            color_B2 = color_Buser
            viscdyn_B2 = viscdyn_Buser
        else
            B1 = B_usercode
            visc_B1 = visc_Buser
            cost_B1 = cost_Buser
            volat_B1 = volat_Buser
            color_B1 = color_Buser
            viscdyn_B1 = viscdyn_Buser
        end 
        

        #obenemos los porcentajes de cada básico para cumplir con la especificación de viscosidad cinemática de la formulación
        
        miu_p = product[10]
        
        miu_1 = visc_B1
        miu_2 = visc_B2
        x1 = log(miu_p/miu_2)/log(miu_1/miu_2)
        x2 = 1-x1
        
        #obtenemos las demas propiedades del producto 
        volat_non_opt = x1*volat_B1 + x2*volat_B2
        
        color_non_opt= x1*color_B1 + x2*color_B2
        
        if product[11]==0
            vdyn_non_opt=0
        else
            vdyn_non_opt = ((viscdyn_B2/viscdyn_B1)^x1)*viscdyn_B1
        end
        
        
    
        #product demand 
    
        demand = demanda[v,2]
    
        #obtenemos los costos de estos básicos de acuerdo a la demanda del producto  
        cost_nonopt = demand*x1*cost_B1 + demand*x2*cost_B2
        
        #obtenemos las demás propiedades del producto que se esta mezclando 
        
        
        #_______________________________________________________________________________
       
        #extraemos los datos del producto 
       
        # product dynamic viscosity [cSt]
        mudyn_product = product[12]
        upper_mudyn = product[16]
   
    
        # Target product dynamic viscosity [cSt]
        mudyntar_product = product[12]
    
    
        # product kinematic viscosity [cSt]
        mukin_product = product[10]
    
    
        # Target color of products
        colorprod_target = product[13]
    
    
        # Target volatility of products 
        volatilityprod_target = product[14]
    



        #encontramos las flags de volatilidad, color y visc dyn 
    
        if colorprod_target == 0 
            flagcolor = 0 
        else 
        flagcolor = 1
        end 
        if volatilityprod_target == 0 
            flagvolat = 0 
        else 
            flagvolat = 1
        end 
        if mudyntar_product == 0 
            flagccs = 0 
            tempccs = 0 
        else 
            flagccs = 1
            tempccs = product[11]

        end


            
        #ahora encontramos la viscosidad dinámica de los básicos 
        
         if tempccs == -10 
            row = 1
        elseif tempccs == -15
            row = 2 
        elseif tempccs == -20 
            row = 3 
        elseif tempccs == -25 
            row = 4
        elseif tempccs == -30
            row = 5
        elseif tempccs == -35
            row = 6
        elseif tempccs == 0 
         row = 0 
        end 
        
        #obtenemos la viscosidad dinámica de los básicos ofrecidos   
        nss = 0 
        mudyn_b1 = Array{Float64,1}(length(basicos[:,1]))
        if tempccs == 0 
        else 
            for l = 1:length(basicos[:,1])
                nss = nss + 1 
                visc_dyn_bas1 = visc_dyn_bas[l]
                mudyn_b1[nss] =  visc_dyn_bas1[row]
            end 
        end
        
        #obtenemos la viscosidad dinámica de los básicos usados para modelar la mezcla 
        nss = 0 
        mudyn_b2 = Array{Float64,1}(length(basics[:,1]))
        if tempccs == 0 
        else
            for o = 1:length(basics[:,1])
            nss = nss + 1 
            visc_dyn_p = visc_dyn_p1[o] 
            mudyn_b2[nss] = visc_dyn_p[row]
            end 
        end
        
        mudyn_basics = append!(mudyn_b1, mudyn_b2)'

        #ya tenemos todos los inputs de los basicos, ahora iniciamos el alg. de optim

        sol = AmplNLSolver(CoinOptServices.couenne)
        m = Model(solver=sol)
        # "bonmin.algorithm=B-Hyb"

        # Scalars
        nb = length(mudyn_basics);    # Number of basic compounds
        ns = 1;    # Number of suppliers
        np = 1;    # Number of products

        # Sets
        ni = 1:nb
        nj = 1:ns;
        nk = 1:np;

        #
        # Bounds for scaling
        #
        up_prod  = 1.0e05;
        up_mudyn = 1.0e04;

    
        # Positive variables
        @variable(m,0<=b[nj,ni]<=100,start=1)
        @variable(m,0<=y1[nk,ni]<=100,start=1)
        @variable(m,0<=y2[nk,ni]<=100,start=1)
        @variable(m,0<=yt[ni]<=100,start=1)


        @variable(m,0.001<=mudyn1[nk]<=1000,start=10)
        @variable(m,0.001<=mudyn2[nk]<=1000,start=10)
        @variable(m,0.001<=mudyn_prod[nk]<=1000,start=10)
 
    

        @variable(m,1<=mukin1[nk]<=1000,start=10)
        @variable(m,1<=mukin2[nk]<=1000,start=10)
        @variable(m,0<=w[nk]<=1,start=0.5)
        @variable(m,0<=p[nk]<=100,start=1)


        @variable(m,0<=color_prod[nk]<=100,start=5)
  


         @variable(m,0<=volatility_prod[nk]<=100,start=10)
    

        # Binary variables
        @variable(m,z1[nk,ni],Bin,start=0)
        @variable(m,z2[nk,ni],Bin,start=0)

        # Objective function
        @objective(m,Min,sum(Cbasic[j,i]*b[j,i] + Ctrans[j,i]*b[j,i] for j in nj, i in ni))

        # Constraints
        @constraint(m,bupper[j in nj,i in ni],
        b[j,i]  <= Supper[j,i]/up_prod)

        @constraint(m,amountbasics[i in ni],
        yt[i]   == sum(b[j,i] for j in nj))

        @NLconstraint(m,eqy1[k in nk,i in ni],
        y1[k,i] == w[k]*p[k]*z1[k,i])

        @NLconstraint(m,eqy2[k in nk,i in ni],
        y2[k,i] == (1-w[k])*p[k]*z2[k,i])

        @constraint(m,eqyt[i in ni],
        yt[i]   == sum(y1[k,i]+y2[k,i] for k in nk))

        @NLconstraint(m,prod[k in nk],
        p[k]    == w[k]*p[k]+(1-w[k])*p[k])

        @constraint(m,demand[k in nk],
        p[k]    >= demand[k]/up_prod)

         @constraint(m,sumz1[k in nk],
         1    == sum(z1[k,i] for i in ni))

        @constraint(m,sumz2[k in nk],
         1    == sum(z2[k,i] for i in ni))

        @NLconstraint(m,eqbasics[k in nk,i in ni],
         0    == z1[k,i]*z2[k,i])

        

         # Physical properties of the 2 chosen basic compounds to manufacture 
        # a given product
        @constraint(m,eqmukin1[k in nk],mukin1[k]==sum(z1[k,i]*mukin_basics[i] for i in ni))

        @constraint(m,eqmukin2[k in nk],mukin2[k]==sum(z2[k,i]*mukin_basics[i] for i in ni))

        if flagccs == 1 

            @constraint(m,eqmudyn1[k in nk],mudyn1[k]==sum(z1[k,i]*mudyn_basics[i] for i in ni)/up_mudyn)

            @constraint(m,eqmudyn2[k in nk],mudyn2[k]==sum(z2[k,i]*mudyn_basics[i] for i in ni)/up_mudyn)
         else flagccs == 0 
        end 

        # Fraction of first basic compound to manufacture product
            @NLconstraint(m,basfrac[k in nk],
            w[k]*(log(mukin2[k])-log(mukin1[k]))==log(mukin_product[k])-log(mukin1[k]))

        # Dynamic viscosity of product

        if flagccs == 1

            @NLconstraint(m,eqmudynprod[k in nk], mudyn_prod[k] == mudyn1[k]*(mudyn2[k]/mudyn1[k])^w[k])  
 
            @constraint(m,mudyntarget[k in nk], mudyn_prod[k] >= mudyntar_product[k]/up_mudyn)
            @constraint(m,mudynproduct[k in nk], mudyn_prod[k]<= upper_mudyn[k]/up_mudyn)
        else flagccs == 0 
        end 

        # Product color
        if flagcolor == 1

             @constraint(m,eqcolorprod[k in nk],color_prod[k]==sum(z1[k,i]*w[k]*color_basics[i] for i in ni)+   
                                                  sum(z2[k,i]*(1-w[k])*color_basics[i] for i in ni))

            @constraint(m,eqcolortarget[k in nk],
                    color_prod[k]    <= colorprod_target[k])
        else flagcolor == 0 
        end 


        # Product volatility
        if flagvolat == 1

            @constraint(m,eqvolprod[k in nk],volatility_prod[k]==sum(z1[k,i]*w[k]*volatility_basics[i] for i in ni)+
                                                     sum(z2[k,i]*(1-w[k])*volatility_basics[i] for i in ni))

            @constraint(m,eqvoltarget[k in nk],
            volatility_prod[k]    <= volatilityprod_target[k])
        else flagvolat == 0 
        end 




        solve(m)

        Z = getobjectivevalue(m);
        mukin_1 = getvalue(mukin1)
        mukin_2 = getvalue(mukin2)
      
        

        #_________________________________________________________________________________
        #termina el algoritmo de optimización e inicia el despliegue de resultados 
        
        if isnan(Z) 
            println("status infeasible")

            #hay que nombrar todas las variables utilizadas y ponerles valor de 0 
            mudyn_optim = 0
            color_optim = 0
            volat_optim = 0     
        

            contador = contador + 1
            new_basics1[contador] = [0 0]
            new_basicsx1[contador] = 0
            new_basicsx2[contador] = 0
            
            new_costx1[contador] = 0
            new_costx2[contador] = 0
            
            new_codex1[contador] = 0
            new_codex2[contador] = 0
           
            new_proveedor1[contador] = [0 0]
            new_proveedorx1[contador] = 0
            new_proveedorx2[contador] = 0

            Z_optim1[contador] = 0
            porcentaje_ahorro[contador] = 0
            demand_1[contador] = 0

            col_opt[contador] = 0
            vol_opt[contador] = 0
            mudyn_opt[contador] = 0
            col_form[contador] = 0
            vol_form[contador] = 0
            mudyn_form[contador] = 0
            mukin_form[contador] = 0
            volat_nonopt[contador]= 0
            color_nonopt[contador] = 0
            vdyn_nonopt[contador] = 0
            mukin_basopt[contador] = 0 
            x1x2_basopt[contador] = 0 
            x1x2_nonopt[contador] = 0 
            mukin_nonopt[contador] = 0 
            
            
        else 
            println("optimal solution found")
             
            #obtenemos los resultados del algoritmo
            B = getvalue(b)
            color_optim = getvalue(color_prod)
            volat_optim = getvalue(volatility_prod)
            mudyn_optim = getvalue(mudyn_prod)
            #println(getvalue(w))
            mukin_gral = mukin_product

            #convertimos los resultados de un diccionario a un "array"
            nss = 0 
            
            #obtenemos las cantidades de los básicos escogidos. Sacamos los valores del diccionario y lo convertimos en un Array
            
            X = Array{Float64,1}(length(B))
            for t = 1:length(B)
                nss = nss+1
                X[nss]= B[1, t]
            end   

            #obtenemos las propiedades físicas calculadas por el algoritmo. los convertimos en arreglos de 1 dim 
            mudyn_optim = mudyn_optim[1]
            color_optim = color_optim[1]
            volat_optim = volat_optim[1]
            
            #ahora eliminamos los ceros e identificamos el código del básico a utilizar y su precio 
            fun(X) = X == 0
            #    find zero element idexes
            zero_elements = find(fun,X)

        
            new_basics = copy(X)
            new_cost = copy(Cbasic')
            new_code = copy(codigo_basics)
            new_proveedor = copy(proveedor)
            
            #obtenemos información de proveedores, cantiedades, costos y ahorros 
        
            contador = contador + 1        
            new_basics1[contador] = round.((deleteat!(new_basics,zero_elements))*1e5);
            new_basics11 = copy(new_basics1[contador])
            new_basicsx1[contador] = new_basics11[1]
            new_basicsx2[contador] = new_basics11[2]
            new_cost1[contador] = deleteat!(new_cost,zero_elements);
            new_cost11 = copy(new_cost1[contador])
            new_costx1[contador] = new_cost11[1]
            new_costx2[contador] = new_cost11[2]
            new_code1[contador] = deleteat!(new_code,zero_elements)
            new_code11 = copy(new_code1[contador])
            new_codex1[contador] = new_code11[1]
            new_codex2[contador] = new_code11[2]
            new_proveedor1[contador] = deleteat!(new_proveedor,zero_elements)
            new_proveedor11 = copy(new_proveedor1[contador])
            new_proveedorx1[contador] = new_proveedor11[1]
            new_proveedorx2[contador] = new_proveedor11[2]
            Z_optim1[contador] = Z*1e5
            porcentaje_ahorro[contador] = ((cost_nonopt - Z*1e5)/cost_nonopt)
            demand_1[contador] = demanda[v,2]
            
            ####################################
            dif_cost[contador] = (cost_nonopt - Z_optim1[contador])/demand_1[contador]
            

            #obtenemos las propiedades físicas de la formulación optimizada y los comparamos con la formulación orginal
            #creamos los arreglos donde se guardará la información 
            
            col_opt[contador] = color_optim
            vol_opt[contador] = volat_optim
            mudyn_opt[contador] = mudyn_optim*1e4
            col_form[contador] = colorprod_target
            vol_form[contador] = volatilityprod_target
            mudyn_form[contador] = mudyn_product
            mukin_form[contador] = mukin_gral
            volat_nonopt[contador] = volat_non_opt
            color_nonopt[contador] = color_non_opt
            vdyn_nonopt[contador] = vdyn_non_opt
            
            
        end
 
    
    
    
    end
end 