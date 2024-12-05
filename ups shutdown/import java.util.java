import java.util.ArrayList;
import java.util.Scanner;

public class Week12Program {
    public static void main(String[] args) {
        // List Of Vars
        ArrayList listOfWords = new ArrayList();
        Scanner scanner = new Scanner(System.in);
        String input = " ";
        String input2 = " ";
            // Counters
        int gobbleCounter = 0;
        int thankfulCounter = 0;
        int fallCounter = 0;
        int studyCounter = 0;




        // Code start
        System.out.println("Input a List oof words one at a time:");
        do { // inputs into listOfWords untell stoped.
            input = scanner.next();
            if (input.equals("STOP")) {
            }else {
                listOfWords.add(input);
            }
        }while(!(input.equals("STOP")));
        // looks through list and sees if something ius true and executes code if so.
        scanner.nextLine(); // clears scanner
       // System.out.println(listOfWords.toString());
        for (int i = 0; i < listOfWords.size(); i++) {

            if (listOfWords.get(i).equals("gobble")) {
                listOfWords.get(i).toString().toUpperCase();
                gobbleCounter++;
            }else if (listOfWords.get(i).equals("~thankful~")) {
                listOfWords.get(i).toString().replace("~", "");
                thankfulCounter++;
            }else if (listOfWords.get(i).toString().toLowerCase().equals("fall")) {
                listOfWords.get(i).toString().toLowerCase();
                fallCounter++;
            }else if (listOfWords.get(i).toString().toLowerCase().contains("study")) {
                System.out.println("What class are you studying for?");
                input2 = scanner.nextLine();
                listOfWords.set(i, input);
                studyCounter++;
            }
        }
        // prints out what was modified
        System.out.println("REGULAR MODIFICATIONS MADE: [" + (gobbleCounter + thankfulCounter + fallCounter + studyCounter) + "]");
        System.out.println("Gobble Counter: [" + (gobbleCounter) + "]");
        System.out.println("Thankful Counter: [" + (thankfulCounter) + "]");
        System.out.println("Fall Counter: [" + (fallCounter) + "]");
        System.out.println("Study Counter: [" + (studyCounter) + "]");
    }
}
