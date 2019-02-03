/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package optimizadordemezclas;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;

/**
 *
 * @author El_jefe
 */
public class Utils {
    
    
    static String readFile(String path, Charset encoding) throws IOException 
    {
        //System.out.println(path);
      byte[] encoded = Files.readAllBytes(Paths.get(path));
      return new String(encoded, encoding);
    }
    
    
    
    public static ArrayList<String> generaDataCsv(String path){
    
        File file = new File(path);
        String lin = "";
        ArrayList<String> res = new ArrayList<String>();
        List<String> aux;

        try {

            Scanner sc = new Scanner(file);
            sc.nextLine();
            while (sc.hasNextLine()) {
                lin = sc.nextLine();
                aux = Arrays.asList(lin.split(","));
                //System.out.println(aux);
                if(!aux.contains("0.0"))
                    res.addAll(aux);
                //System.out.println(lin);
            }
            sc.close();
        } 
        catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        
        //System.out.println(res);
    
        return res;
    }
    
    public static ArrayList<String[]> getDataFromCsv(String path, boolean saltarHeader){
        ArrayList<String[]> res = new ArrayList<String[]>();
        File file = new File(path);
        String lin = "";
        List<String> aux;

        try {

            Scanner sc = new Scanner(file);
            if(saltarHeader && sc.hasNextLine())
                sc.nextLine();
            while (sc.hasNextLine()) {
                lin = sc.nextLine();
                res.add(lin.split(","));
            }
            sc.close();
        } 
        catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        
        
        return res;   
    }
    public static String[] leeValRes(String path){
        File file = new File(path);
            String lin = "";
            String[] res = null;

            try {

                Scanner sc = new Scanner(file);
                if (sc.hasNextLine()) {
                    lin = sc.nextLine();
                    res = lin.split(";");
                }
                sc.close();
            } 
            catch (FileNotFoundException e) {
                e.printStackTrace();
            }
            //for(String s : res)
            //    System.out.println(s);
            //System.out.println(res);

            return res;
    
    }
    
    public static ArrayList<String> generaCol(String path, int col){
    
        File file = new File(path);
        String lin = "";
        ArrayList<String> res = new ArrayList<String>();
        String[] aux;

        try {

            Scanner sc = new Scanner(file);
            sc.nextLine();
            while (sc.hasNextLine()) {
                lin = sc.nextLine();
                aux = lin.split(",");
                //System.out.println(aux);
                 res.add(aux[col-1]);
                //System.out.println(lin);
            }
            sc.close();
        } 
        catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        
        //System.out.println(res);
    
        return res;
        
    }
    
}