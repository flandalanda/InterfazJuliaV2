/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package optimizadordemezclas;

import java.nio.charset.Charset;
import java.util.ArrayList;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;

/**
 *
 * @author El_jefe
 */
public class UtilsTest {
    
    public UtilsTest() {
    }
    
    @BeforeClass
    public static void setUpClass() {
    }
    
    @AfterClass
    public static void tearDownClass() {
    }

    

    /**
     * Test of leeValRes method, of class Utils.
     */
    @Test
    public void testLeeValRes() {
        System.out.println("leeValRes");
        String[] expResult ={"[719090.0]","748236.0"};
        String[] result = Utils.leeValRes("valoresResTest.txt");
        assertArrayEquals(expResult, result);
    }
    
}
