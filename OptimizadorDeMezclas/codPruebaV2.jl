# Optimization formulation for oil manufacturing
#
using JuMP, AmplNLWriter, CoinOptServices, DataFrames, CSV

#_____________________________________________________________________________________________

#llamamos a las bases de datos 


#llamamos a las bases de datos 
inventarios = CSV.read( "inventario en planta.csv")
inventarios = convert(Array,inventarios)
basicos = CSV.read("info basicos.csv")
basicos = convert(Array,basicos)
restricciones = CSV.read("restricciones de basicos.csv")
restricciones = convert(Array, restricciones)
grupos = CSV.read("basicos por grupo.csv")
grupos = convert(Array{Any,2}, grupos)
formulaciones = CSV.read("formulaciones.csv")
formulaciones = convert(Array{Any,2},formulaciones)

#identificamos el producto a tratar (INPUT usuario)
#print("indique el código de producto que desea ver")
#z = parse(Int32,readline(STDIN))
#z1 = string(z)

#lee el codigo del producto
z1INTERFAZ = ARGS[1]
z2INTERFAZ = parse(Float64, ARGS[2])

y = findfirst(formulaciones[:,3],z1INTERFAZ)
#println("index formulaciones", y)


product = formulaciones[y,:]


#encontramos las restriccciones de básicos de este producto 
y = findfirst(restricciones[:,1],z1INTERFAZ)
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
for i = 1:5
    nss = nss+1
    if y1[i]==1 
        g[:,nss]=grupos[:,2*i]
        else 
        g[:,nss]= zeros(Int8,lg,1)
        end 
    end 
    
#find the zero elements in the arrays and delete them 
basico = Array{Any,1}(5)
ns = 0
for i = 1:5
    ns = ns+1
    x = g[:,i]
    fun(x) = x == 0
    zero_elements = find(fun,x)
    new_vector = deleteat!(g[:,i],zero_elements)
    basico[ns] = new_vector
end

#construimos un vector con todos los básicos permitidos para formar este producto
b1 = append!(basico[1],basico[2])
b2 = append!(b1,basico[3])
b3 = append!(b2,basico[4])
b4 = append!(b3,basico[5])



na = 0
fin = Array{Any,1}(length(y3))
#agregamos a este vector los básicos especificados por formula, si ya se encuentran en este vector, no se agregan
for k = 1:length(y3)
    na = na+1
    fin = findfirst(b4,y3[k])
    
    if fin > 0 
        else fin == 0 
        push!(b4,y3[k])
    end
        
    end 
#ahora hay que encontrar la información de costo, viscosidad dinámica a 100°C, viscosidad cinemática @T de producto, cantidad máxima que se puede comprar, 

#obtenemos los datos de la hoja de formulaciones [temp de ccs, color max, volatilidad max ]
indice = findfirst(formulaciones[:,3],z1INTERFAZ)
temp_ccs = formulaciones[indice,11]
colorf = formulaciones[indice,13]
volatf = formulaciones[indice, 14]

#creamos los vectores donde se guardará la información 
cost = Array{Any,1}(length(b4))
visckin = Array{Any,1}(length(b4))
ccs = Array{Any,1}(length(b4))
color = Array{Any,1}(length(b4))
volat = Array{Any,1}(length(b4))
cantidad = Array{Any,1}(length(b4))
#las banderas que indican si hay o no restricciones de color, volatilidad y visckin
flagccs = Array{Int8,1}(1)
flagcolor = Array{Int8,1}(1)
flagvolat = Array{Int8,1}(1)

#anclamos los contadores
nss = 0 
ns = 0 
na = 0 

for i = 1:length(b4)
    nss = nss+1
    #indice de costo en "inventario en planta.csv" 
    indc=findfirst(inventarios[:,2],b4[i])
    #costo de los basicos 
    cost[nss]= inventarios[indc,4]
    #cantidad de basicos en inventario 
    cantidad[nss] = inventarios[indc,3]
    #indice de básico en "info basicos.csv"
    indbas = findfirst(basicos[:,2],b4[i])
    #viscosidad dinamica a 100°C de los basicos 
    visckin[nss] = basicos[indbas,3]
  
    
    #hay cierta información que es requerida o no de acuerdo a las especificaciones del producto. En este caso, la temperatura a la cual se mide el ccs indica q datos iniciales requerimos 
    if temp_ccs == 0
        flagccs = 0 #no todoslos productos toman en cuenta las propiedades a baja temp. en este caso dejamos el vector en 0 
        ccs[nss]=0
    elseif temp_ccs == -10 
        ccs[nss] = basicos[indbas,9]
        flagccs = 1
    elseif temp_ccs == -15
        ccs[nss] = basicos[indbas,10]
        flagccs = 1
    elseif temp_ccs == -20
        ccs[nss] = basicos[indbas, 11]
        flagccs = 1
    elseif temp_ccs == -25 
        ccs[nss] = basicos[indbas, 12]
        flagccs = 1
    elseif temp_ccs == -30 
        ccs[nss] = basicos[indbas, 13]
        flagccs = 1
    elseif temp_ccs == -35
        ccs[nss] = basicos[indbas,14]
        flagccs = 1
        end 
    #también, para ciertos productos se requiere especificación de color y volatilidad 
    if colorf == 0 
        flagcolor = 0 
        else 
        ns = ns + 1 
        color[ns] = basicos[indbas,6]
        flagcolor = 1
        end 
    if volatf == 0 
        flagvolat = 0 
        else 
        na = na + 1
        volat[na]= basicos[indbas,7]
        flagvolat = 1
        end 
end



#= _________________________________________________________________________________________________________________________
=#

sol = AmplNLSolver(CoinOptServices.couenne)
m = Model(solver=sol)
# "bonmin.algorithm=B-Hyb"

# Scalars
nb = length(b4);    # Number of basic compounds
ns = 1;    # Number of suppliers
np = 1;    # Number of products

# Sets
ni = 1:length(b4);
nj = 1:1;
nk = 1:1;
np = copy(ni);
#
# Bounds for scaling
#
up_prod  = 1.0e05;
up_mudyn = 1.0e04;

# Cost of basic products [$/gal]
Cbasic = cost';
          
# Transportation cost [$/gal]
Ctrans = fill(0,length(b4))'
          
# Minimum purchased amount [gal]
Slower = fill(0,length(b4))'

# Maximum purchased amount [gal]
Supper = cantidad'

# Dynamic viscosity of basic compounds at given temperature [cP]
mudyn_basics = ccs'

# Kinematic viscosity of basic compounds at given temperature [cP]
mukin_basics = visckin' 
    
# product dynamic viscosity [cSt]
mudyn_product = product[12]

# Target product dynamic viscosity [cSt]
mudyntar_product = product[12]

# product kinematic viscosity [cSt]
mukin_product = product[10]


# Nominal color of basic compounds
color_basics = color' 
    
# Target color of products
colorprod_target = product[13]

# Nominal volatility of basic compounds
volatility_basics = volat'

# Target volatility of products 8  13  20  13  17  6  22  25]
volatilityprod_target = product[14]


#Product demand
#print("indique cantidad de producto a producir (kg)")
#demand = parse(Int32,readline(STDIN))
demanda = z2INTERFAZ
demand = z2INTERFAZ
    

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
#println(getvalue(z1))
#println(getvalue(z2))
#println(getvalue(b))
B = getvalue(b)
color_prod = println(getvalue(color_prod))
volatility_prod = (getvalue(volatility_prod))
mudyn_prod = (getvalue(mudyn_prod))
#println(getvalue(mukin_product))
#println(getvalue(w))


#convertimos los resultados de un diccionario a un "array" 
nss = 0 
X = Array{Float64,1}(length(B))
for i = 1:length(B)
    nss = nss+1
    X[nss]= B[1, i]
    end  

if flagcolor == 1
c_prod = color_prod[1]
    else 
    c_prod = 0 
    end 
if flagvolat == 1 
v_prod = volatility_prod[1]
    else 
    v_prod = 0
    end 
if flagccs == 1 
m_prod = mudyn_prod[1]*1e4
    else 
    m_prod = 0 
    end 

#ahora eliminamos los ceros e identificamos el código del básico a utilizar y su precio 



    fun(X) = X == 0
    #find zero element idexes
    zero_elements = find(fun,X)

new_basics = copy(X)
new_cost = copy(cost)
new_code = copy(b4)

new_basics = round.((deleteat!(new_basics,zero_elements))*1e5); 
new_cost = deleteat!(new_cost,zero_elements); 
new_code = deleteat!(new_code,zero_elements);  

total_cost = round.(new_cost.*new_basics)

#despliegue de resultados
println("formulación sin cambios")
println(product)
#guardamos valores para la interfaz grafica
valoresInter = ""
for i =1:15
    valoresInter = string(valoresInter,";",product[i][1])
end
valoresInter = valoresInter[2:end]
#println(valoresInter)                                                                                                                  
#abre el archivo en el que est� las variables de la interfaz
archivo = open("producto.txt","w")
write(archivo, valoresInter)
close(archivo)
#obtenemos el costo de producción sin cambios en la formulación 
costo = Array{Any,1}(length(y3))
mukin_formula = Array{Any,1}(length(y3))

nss = 0  
for i = 1:length(y3)
    nss = nss + 1 
    indice = findfirst(inventarios[:,2],y3[i])
  
   costo[nss] = inventarios[indice,4]
    index = findfirst(basicos[:,2],y3[i])
    mukin_formula[nss] = basicos[index,3]
    
    end 


#obtenemos la viscosidad cinemática de los básicos por fórmula 

visc_prod = product[10]
x1 = (log(visc_prod)/log(mukin_formula[1]))/(log(mukin_formula[2])/log(mukin_formula[1]))
x2 = 1-x1 

cost_no_opt = costo[1]*x1*demanda[1] + costo[2]*x2*demanda[1]

#obtenemos el nombre de los básicos optimos 
nss = 0 
nombres_basicos = Array{Any,1}(length(new_code))
for i = 1:length(new_code)
     nss = nss + 1 
    indice = findfirst(basicos[:,2], new_code[i])
    nombres_basicos[nss] = basicos[indice,1]
   
    end 

println("el costo total de la mezcla de basicos sin optimizar la formulacion es ", cost_no_opt, " pesos")
valoresInter = cost_no_opt
if Z == 0
    letreroNA = "Basicos,costo_unitario_mxn_kg,cantidad_kg,costo_por_basico
NA,NA,NA,NA
NA,NA,NA,NA
NA,NA,NA,NA"

    archivo1 = open("tablaRes.txt","w")
    write(archivo1, letreroNA)
    close(archivo1)

    valoresInter = string(valoresInter,";","NA")
    #abre el archivo en el que est� las variables de la interfaz
        archivo = open("valoresRes.txt","w")
    write(archivo, valoresInter)
    close(archivo)
    else 

println("el costo total de mezcla de basicos con la formulación optimizada es ", round(Z*1e5), " pesos" )    
answer = DataFrame( nombre = nombres_basicos, codigo = new_code, costo_unitario_mxn_kg = new_cost, cantidad_kg = new_basics, costo_por_basico = total_cost)
CSV.write("tablaRes.txt",answer)
valoresInter = string(valoresInter,";",round(Z*1e5))
#abre el archivo en el que est� las variables de la interfaz
archivo = open("valoresRes.txt","w")
write(archivo, valoresInter)
close(archivo)
    end 
println("el dinero que se ahorra con la fórmula optimizada es", cost_no_opt - Z*1e5)

product_info = DataFrame(viscosidad_kin = mukin_product, viscosidad_dyn = m_prod, color = c_prod, volatilidad = v_prod)
CSV.write("nuevaTablaProductos.txt",product_info)                                                                                                                                                  

