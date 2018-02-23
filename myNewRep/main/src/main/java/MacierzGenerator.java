import java.util.Scanner;

/**
 * Created by ziobro on 2/23/2018.
 */
public class MacierzGenerator {

    private double[][] macierz;
    private int n;
    private int m;

    public MacierzGenerator(int n, int m) {
	  System.out.println("Tworze macierz " + n + " X " + m);

	  this.macierz = new double[n][m];
    }

    public void generujliczby(){
	  for (int i = 0; i < macierz.length; i++) {
		for (int j = 0; j < macierz[i].length; j++) {
		    macierz[i][j] = (int)(Math.random()*100);
		}
	  }
    }
    public void displayArray(){
	  for (int i = 0; i < macierz.length; i++) {
		for (int j = 0; j < macierz[i].length; j++)
		    System.out.print(macierz[i][j] + "   ");
		    System.out.println();
		}
	  }


    public int getN() {
	  return n;
    }

    public void setN(int n) {
	  System.out.println("Podaj wymiar n : ");
	  Scanner sc = new Scanner(System.in);
	  this.n = sc.nextInt();
    }

    public int getM() {
	  return m;
    }

    public void setM(int m) {
	  System.out.println("Podaj wymiar m : ");
	  Scanner sc = new Scanner(System.in);
	  this.m = sc.nextInt();
    }
}


