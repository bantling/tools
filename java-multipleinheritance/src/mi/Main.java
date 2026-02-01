package mi;

public class Main {
	public static void main(String[] args) {
		for (int i = 1; i < 10; i++) {
			final DogCow dc = new DogCow();
			
			System.out.println(
				"DogCow " + i +
				" is combined breed " +
				dc.getBreed() +
				" named " +
				dc.getName() +
				" born on " +
				dc.getBirthDate() +
				" with next checkup of " +
				dc.nextCheckup()
			);
		}
	}
}
