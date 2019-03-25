#compras parte 2 
using JuMP, CouenneNL, CSV, DataFrames

#llamamos a los inputs generales
#se ponen los inputs ya en formato para entrar al programa 

mukin = CSV.read("MUKIN.csv")
mukin_basics = convert(Array{Float64,2},mukin)'  #
#cmax = CSV.read("CMAX.csv")
#Supper = convert(Array{Float64,2},cmax)' #
#cmin = CSV.read("CMIN.csv")
#Slower = convert(Array{Float64,2},cmin)'  #
precio = CSV.read("PRECIO.csv")
#Cbasic = convert(Array{Float64,2},precio)'#
precio = convert(Array{Float64,2},precio)
basicos = CSV.read("BASICO.csv")
basicos = convert(Array{Any,2},basicos) # nombre y código 
proveedor = CSV.read("PROVEEDORE.csv")
proveedor = convert(Array{String,2},proveedor)
proveedor11 = convert(Array{String,2},proveedor)
transporte = CSV.read("TRANSPORTE.csv")
Ctrans = convert(Array{Float64,2},transporte)  #
tasa = CSV.read("TASA.csv")
tasa = convert(Array,tasa)
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
ddp = CSV.read("DDP.csv")
ddp = convert(Array{Float64,2},ddp)'

#ahora llamamos a los inputs del programa anterior 

Cbasic = CSV.read("Cbasic")
Cbasic = convert(Array{Float64,2}, Cbasic)'
Cbasic = reshape(Cbasic, length(Cbasic))
Supper = CSV.read("Supper")
Supper = convert(Array{Float64,2},Supper)' 
Supper = reshape(Supper, length(Supper))
Slower = CSV.read("Slower")
Slower = convert(Array{Float64,2},Slower)'
Slower = reshape(Slower, length(Slower))
total_inputs = CSV.read("total_inputs")
total_inputs = convert(Array{Int8,2}, total_inputs)
total_inputs = reshape(total_inputs,1)
productos_permitidos = CSV.read("productos_permitidos")
productos_permitidos = convert(Array{Int32,2}, productos_permitidos)'
productos_permitidos = reshape(productos_permitidos, length(productos_permitidos))

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

#indica el usuario cuantos productos quiere analizar 
#este será un input del GUI muchachos 
println("indique que oferta escogería normalmente: ")
oferta_escogida = parse(Int32,readline(STDIN))

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
    #eliminamos de la lista de básicos para simular mezclas aquellos que se estan ofreciendo

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

    #les agregamos un costo de transporte estandar
    ctrans_p1 = fill(0.11, length(basics[:,1]))

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
    #__________________________________________________________________________________________________

    #creamos los arrelgos donde guardaremos los resultados


    new_cost1  = Array{Any,1}(p_analizados)
    new_basics1 = Array{Any,1}(p_analizados)
    new_code1 = Array{Any,1}(p_analizados)
    new_proveedor1 = Array{Any,1}(p_analizados)
    Z_optim1 = Array{Any,1}(p_analizados)
    cost_nonopt1 = Array{Any,1}(p_analizados)
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
    new_visckin1 = Array{Any,1}(p_analizados)
    new_visckinx1 = Array{Any,1}(p_analizados)
    new_visckinx2 = Array{Any,1}(p_analizados)
    ahorro_ = Array{Any,1}(p_analizados)
    new_costfin = Array{Any,1}(p_analizados)
    demanda_ = Array{Any,1}(p_analizados)
    nonopt_B1 = Array{Any,1}(p_analizados)
    nonopt_visc_B1 = Array{Any,1}(p_analizados)
    nonopt_cost_B1 = Array{Any,1}(p_analizados)
    nonopt_volat_B1 =Array{Any,1}(p_analizados)
    nonopt_color_B1 = Array{Any,1}(p_analizados)
    nonopt_viscdyn_B1 = Array{Any,1}(p_analizados)
            
    nonopt_B2 = Array{Any,1}(p_analizados)
    nonopt_visc_B2 = Array{Any,1}(p_analizados)
    nonopt_cost_B2 = Array{Any,1}(p_analizados)
    nonopt_volat_B2 = Array{Any,1}(p_analizados)
    nonopt_color_B2 = Array{Any,1}(p_analizados)
    nonopt_viscdyn_B2 = Array{Any,1}(p_analizados)

 
           
    #__________________________________________________________________________________________________

    #inicia algoritmo por producto 

    #identificamos el producto a analizar 
    contador = 0 
    for v = 1:p_analizados 
        println("OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO", "     ", v)
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
            viscdyn_B2 = 0 
            viscdyn_B1 = 0 
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
        println("VISCOSIDAD DINAMICA BUSER B2", " ", viscdyn_B2)
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
        
        #guardamos la información de los básicos con los que se va a comprar la respuesta del algoritmo 
      
        
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

        #sol = AmplNLSolver(CoinOptServices.couenne)
        #m = Model(solver=sol)
        # "bonmin.algorithm=B-Hyb"
        m = Model(solver=CouenneNLSolver())

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

        # Inventory contraint
        #@constraint(m,eqinv[i in ni],inv_e[i]+yt[i] <= inv_p[i])

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
        #termina el algoritmo de optimización e inicia el obtención de resultados 
        
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
            cost_nonopt1[contador] = 0
            ahorro_[contador]=0
            demanda_[contador] = 0
            
            nonopt_B1[contador] = 0 
            nonopt_visc_B1[contador] = 0
            nonopt_cost_B1[contador] = 0 
            nonopt_volat_B1[contador] = 0
            nonopt_color_B1[contador] = 0
            nonopt_viscdyn_B1[contador] = 0 
            
            nonopt_B2[contador] = 0
            nonopt_visc_B2[contador] = 0
            nonopt_cost_B2[contador] = 0 
            nonopt_volat_B2[contador] = 0
            nonopt_color_B2[contador] = 0
            nonopt_viscdyn_B2[contador] = 0 
             
            
            
        else 
            println("optimal solution found")
             
            #obtenemos los resultados del algoritmo
            B = getvalue(b)
            color_optim = getvalue(color_prod)
            volat_optim = getvalue(volatility_prod)
            mudyn_optim = getvalue(mudyn_prod)
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
            
            #ahora identificamos los elementos cero en el arreglo de resultados
            fun(X) = X == 0
            #    find zero element idexes
            zero_elements = find(fun,X)
            
            #guardamos la cantidad de basicos, costos, codigos y proveedores en nuevas variables para poder manipularlas sin afectar futuros resultados
            new_basics = copy(X)
            new_cost = copy(Cbasic')
            new_code = copy(codigo_basics)
            new_proveedor = copy(proveedor)
            new_visckin = copy(mukin_basics')
            
            
            #obtenemos información de proveedores, cantiedades, costos y ahorros 
        
        
            contador = contador + 1  
            
            #costo optimizado y sin optimizar
            Z_optim1[contador] = Z*1e5
            cost_nonopt1[contador] = cost_nonopt
            demanda_[contador] = demanda[v,2]
            
            #cantidad de basico
            new_basics1[contador] = round.((deleteat!(new_basics,zero_elements))*1e5);
            new_basics11 = copy(new_basics1[contador])
            new_basicsx1[contador] = new_basics11[1]
            new_basicsx2[contador] = new_basics11[2]
            
            #codigo de basicos
            new_code1[contador] = deleteat!(new_code,zero_elements)
            new_code11 = copy(new_code1[contador])
            new_codex1[contador] = new_code11[1]
            new_codex2[contador] = new_code11[2]
            
            #proveedores de basicos
            new_proveedor1[contador] = deleteat!(new_proveedor,zero_elements)
            new_proveedor11 = copy(new_proveedor1[contador])
            new_proveedor_x1 = new_proveedor11[1]
            new_proveedor_x2 = new_proveedor11[2]
            new_proveedorx1[contador] = string(new_proveedor_x1)
            new_proveedorx2[contador] = string(new_proveedor_x2)
            
            #costo de basicos
            if new_proveedorx1[contador] == "p1"
                    
                new_costx1[contador] = "NA"
                new_costx2[contador] = "NA"
                Z_optim1[contador] = "NA"
                dif_cost[contador] = "NA"
                ahorro_[contador] = "NA"
                new_costfin[contador] = "NA"
                    
            elseif new_proveedorx1[contador] != "p1"
                if new_proveedorx2[contador]!= "p1"
                    new_costx1[contador] = "NA"
                    new_costx2[contador] = "NA"
                    Z_optim1[contador] = "NA"
                    dif_cost[contador] = "NA"
                    ahorro_[contador] = "NA"
                    new_costfin[contador] = 0
                    
                    else 
                        new_cost1[contador] = deleteat!(new_cost,zero_elements);
                        new_cost11 = copy(new_cost1[contador])
                        new_costx1[contador] = new_cost11[1]
                        new_costx2[contador] = new_cost11[2]/1.5
                        cost_inf = new_costx2[contador]*0.5*new_basicsx2[contador]
                        Z_optim1[contador] = Z*1e5 - cost_inf
                        dif_cost[contador] = cost_nonopt - Z_optim1[contador]
                
                        if dif_cost[contador]>0
                            ahorro_[contador] = "SI"
                            index = findfirst(Cbasic, new_costx1[contador])
                            precio_fin = precio[index]
                            new_costfin[contador] = (precio_fin-new_costx1[contador])*new_basicsx1[contador]
                        
                            elseif dif_cost[contador] <0
#                                ahorro_[contador] = "NO"
                                ahorro_[contador] = dif_cost[contador]
                                new_costfin[contador]  = 0
                            end
             
                        
                    end
                
                end 
                
                
            
            #viscosidad de basicos 
            new_visckin1[contador] = deleteat!(new_visckin,zero_elements)
            new_visckin11 = copy(new_visckin1[contador])
            new_visckinx1[contador]= new_visckin11[1]
            new_visckinx2[contador] = new_visckin11[2]
            
           
           #información de básicos non opt
            nonopt_B1[contador] = B1 
            nonopt_visc_B1[contador] = visc_B1
            nonopt_cost_B1[contador] = cost_B1 
            nonopt_volat_B1[contador] = volat_B1
            nonopt_color_B1[contador] = color_B1
            nonopt_viscdyn_B1[contador] = viscdyn_B1 
            
            nonopt_B2[contador] = B2 
            nonopt_visc_B2[contador] = visc_B2
            nonopt_cost_B2[contador] = cost_B2 
            nonopt_volat_B2[contador] = volat_B2
            nonopt_color_B2[contador] = color_B2
            nonopt_viscdyn_B2[contador] = viscdyn_B2 
    
            #end

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
    #=___________________________________________________________________________________
    termina algoritmo por producto =#
    
    #=______________________________________________________________________________________
    tablas de extracción de resultados =#

    #obtenemos los resultados desglosados de los básicos escogidos por el algoritmo 
    resultados0 = DataFrame(code_x1 = new_codex1, code_x2 = new_codex2, cost_x1 = new_costx1, cost_x2 = new_costx2, cant_x1 = new_basicsx1, cant_x2 = new_basicsx2, proveedor_x1 = new_proveedorx1, proveedor_x2 = new_proveedorx2, visckin_x1 = new_visckinx1, visckin_x2 = new_visckinx2, mukin = mukin_form)    
    CSV.write("resultados0", resultados0)
    #resultados de propiedades de producto : alg optim, formula, alg nonopt
    resultados1 = DataFrame(mukin = mukin_form, mudyn_formula = mudyn_form, mudyn_opt = mudyn_opt, mudyn_nonopt = vdyn_nonopt, color_formula = col_form, color_optim = col_opt, color_nonopt = color_nonopt, volat_formula = vol_form, volat_optim = vol_opt, volat_nonopt = volat_nonopt)
    CSV.write("resultados1", resultados1)
    #resultados de dinero 
    resultados2 = DataFrame(proveedor = new_proveedorx1, cantidad = new_basicsx1, costo_optim = Z_optim1, cost_nonopt = cost_nonopt1, ahorro = ahorro_, cost_financiero = new_costfin, demanda = demanda_)
    CSV.write("resultados2", resultados2) 
    resultados3 = DataFrame(codex1_nonopt = nonopt_B1, codex2_nonopt = nonopt_B2, nonopt_viscx1 = nonopt_visc_B1, nonopt_viscx2 = nonopt_visc_B2, nonopt_costx1 = nonopt_cost_B1, nonopt_costx2 = nonopt_cost_B2, nonopt_volatx1 = nonopt_volat_B1 , nonopt_volatx2 = nonopt_volat_B2  ) 
end

#=_______________________________________________________
    inicia analisis de resultados. Se usará solamente la tabla resultados2 =#
    
    #primero, dividimos la tabla de resultados2 en tablas individuales para cada proveedor. cada renglón del arreglo corresponde a un proveedor
res_prov = Array{Any,1}(length(proveedor11))
ns = 0 
    for i = 1:length(proveedor11)
    ns = ns + 1
    nss = 0 
    results = Array{Any,1}(p_analizados)
        for j = 1:p_analizados
        nss = nss + 1
            if proveedor11[i] == resultados2[j,1]
            results[nss] = j
            else
            results[nss] = 0 
            end 
        res_prov[ns] = results
            
    end
    end
    
    
   ans_prov1 = Array{Any,1}(length(proveedor11))
    ns = 0 
    for i = 1:length(proveedor11)
        ns = ns + 1
        nss = 0 
    
        ans_prov = Array{Any,1}(length(resultados2[1,:]))
        vect = res_prov[i]
        fun(vect) = vect == 0 
        zero_elements = find(fun, vect)
        res = convert(Array,resultados2)
        
        for j = 1:length(resultados2[1,:])
                nss = nss + 1
                ans_prov[nss] = deleteat!(res[:,j], zero_elements)
        end
        ans_prov1[ns] = ans_prov
    
    
        if length(zero_elements) == p_analizados
            ans_prov1[i] = [proveedor11[i], 0, 0, 0, 0, 0, 0]
        else
    
    end
    end

    #visión general
       
    demanda_total_an = sum(resultados2[:,7])
    demanda_total_an1 = sum(resultados2[:,7])
    demanda_total_an = [demanda_total_an]
    demanda_total_an = DataFrame(info = demanda_total_an)
    CSV.write("demanda total analizada", demanda_total_an)
    
    demanda_total = sum(demanda[:,2])
    demanda_total1 = sum(demanda[:,2])
    demanda_total = [demanda_total]
    demanda_total = DataFrame(info = demanda_total)
    CSV.write("demanda total ", demanda_total)

    per_demanda = (demanda_total_an1/demanda_total1)*100

    per_demanda = [per_demanda]
    per_demanda = DataFrame(info = per_demanda)
    CSV.write("porcentaje de demanda", per_demanda)

    total_productos = length(demanda[:,2])
    total_productos1 = length(demanda[:,2])
    total_productos = [total_productos]
    total_productos = DataFrame(info = total_productos)
    CSV.write("total de productos", total_productos)

    per_productos = (p_analizados/total_productos1)*100
    per_productos = [per_productos]
    per_productos = DataFrame(info = per_productos)
    CSV.write("porcentaje de productos", per_productos)
    

    
    #analisis por proveedor 
    
    #para cuantos productos se escoge este proveedor 
    prod_prov = Array{Any,1}(length(proveedor11))
    dem_tot = Array{Any,1}(length(proveedor11))
    cost_fin = Array{Any,1}(length(proveedor11))
    cant = Array{Any,1}(length(proveedor11))
    aho = Array{Any,1}(length(proveedor11))
    per_dem = Array{Any,1}(length(proveedor11))

    ns = 0 
    for i = 1:length(proveedor11)
        ns = ns + 1
        prov = ans_prov1[i]
        if prov[2] == 0 
            prod_prov[ns] = 0         
            dem_tot[ns] = 0 
            per_dem[ns] = 0 
            cost_fin[ns] = 0 
            cant[ns] = 0 
            aho[ns] = 0 
  
        else
            prod_prov[ns] = length(prov[1])
            dem_tot[ns] = sum(prov[7])
            per_dem[ns] = dem_tot[ns]/demanda_total_an1
            cost_fin[ns] = sum(prov[6])
            cant[ns] = sum(prov[2])        
            prov5 = prov[5]
            prov3 = prov[3]
            prov4 = prov[4]
            a_horro = Array{Any,1}(length(prov5))
            nss = 0 
        
        for i = 1:length(prov5)
            nss = nss + 1
            if prov5[i] == "SI"
                a_horro[nss] = prov4[i]-prov3[i]
            else
                a_horro[nss] = 0
                end
        end
            aho[ns] = sum(a_horro)
        end 
end

answer = DataFrame(producto = prod_prov, demanda = dem_tot, per_demanda = per_dem, cost_fin = cost_fin, cantidad = cant, ahorro = aho)
    
#___________________________________________________________________________________________________________END    

#en vista de que julia es tonto, vamos a guardar cada uno de los incisos del resultado en un CSV diferente
#Todos los archivos serán arreglos del mismo tamaño

prod_prov = DataFrame(info = prod_prov)
dem_tot = DataFrame(info = dem_tot)
per_dem = DataFrame(info = per_dem)
cost_fin = DataFrame(info = cost_fin)
cant = DataFrame(info = cant)
aho = DataFrame(info = aho)

CSV.write("proveedor", prod_prov)
CSV.write("demanda total", dem_tot)
CSV.write("porcentaje demanda", per_dem)
CSV.write("costo financiero", cost_fin)
CSV.write("cantidad kg", cant)
CSV.write("ahorro", aho)


