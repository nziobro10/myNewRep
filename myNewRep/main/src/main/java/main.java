import java.io.*;
import java.util.Scanner;

/**
 * Created by ziobro on 2/23/2018.
 */

public class main {

    public static void main(String[] args) throws IOException {


	  Scanner sc = new Scanner(System.in);
	  System.out.println("Generator blablabla put smt to start....");
	  while ((sc.nextInt() != 0) || (sc.nextLine() != "exit")) {

		System.out.println("Podaj wymiar a : ");
		int a = sc.nextInt();
		System.out.println("Podaj wymiar b : ");
		int b = sc.nextInt();

		MacierzGenerator macierz1 = new MacierzGenerator(a, b);


		macierz1.generujliczby();
		macierz1.displayArray();

		System.out.println("0 to exit.");
	  }

    }

}
