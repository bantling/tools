package mi;

import static java.time.temporal.ChronoField.YEAR;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;

public class DogCow implements Dog, Cow {
	private final OffsetDateTime dogCowBdate = OffsetDateTime.of(
		OffsetDateTime.now().get(YEAR) - (int)(Math.random() * 5),
		(int)(Math.random() * 12) + 1,
		(int)(Math.random() * 28) + 1,
		(int)(Math.random() * 24),
		(int)(Math.random() * 60),
		0,
		0,
		ZoneOffset.UTC
	);
	
	private final DogData dogData = new DogData(
		"Border Collie",
		"Nate",
		dogCowBdate
	);
	
	private final CowData cowData = new CowData(
		"Angus",
		dogCowBdate
	);
	
	@Override
	public DogData getDogData() {
		return dogData;
	}
	
	@Override
	public CowData getCowData() {
		return cowData;
	}
	
	@Override
	public OffsetDateTime nextCheckup() {
		// Check both Dog and Cow, choose whichever one comes first
		final OffsetDateTime nextDogCheckup = Dog.super.nextCheckup();
		final OffsetDateTime nextCowCheckup = Cow.super.nextCheckup();
		
		return nextDogCheckup.isBefore(nextCowCheckup) ? nextDogCheckup : nextCowCheckup;
	}
	
	@Override
	public String getBreed() {
		return Dog.super.getBreed() + " " + Cow.super.getBreed();
	}
	
	@Override
	public OffsetDateTime getBirthDate() {
		return Dog.super.getBirthDate();
	}
}
