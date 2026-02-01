package mi;

import static java.time.temporal.ChronoField.DAY_OF_MONTH;
import static java.time.temporal.ChronoField.HOUR_OF_DAY;
import static java.time.temporal.ChronoField.MINUTE_OF_DAY;
import static java.time.temporal.ChronoField.MONTH_OF_YEAR;
import static java.time.temporal.ChronoField.NANO_OF_SECOND;
import static java.time.temporal.ChronoField.SECOND_OF_MINUTE;
import static java.time.temporal.ChronoField.YEAR;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

/**
 * The fields of data that Foo needs to operate on
 */
class DogData {
	final String breed;
	final String name;
	final OffsetDateTime birthDate;

	DogData(String breed, String name, OffsetDateTime birthDate) {
		this.breed = breed;
		this.name = name;
		this.birthDate = birthDate;
	}
}

public interface Dog {
	/**
	 * The method the class has to implement to return a DogData instance, from one its own fields.
	 * 
	 * @return dog data
	 */
	DogData getDogData();
	
	/**
	 * Return the next time the dog should go to the vet for a checkup,
	 * which is annually, one week after the dog's birthday.
	 * 
	 * @return date of next checkup.
	 */
	default OffsetDateTime nextCheckup() {
		final OffsetDateTime now = OffsetDateTime.now();
		
		final OffsetDateTime today = now.
			minusHours(now.get(HOUR_OF_DAY)).
			minusMinutes(now.get(MINUTE_OF_DAY)).
			minusSeconds(now.get(SECOND_OF_MINUTE)).
			minusSeconds(now.get(NANO_OF_SECOND));
		
		final OffsetDateTime bday = getDogData().birthDate;
		final int thisYear = now.get(YEAR);
		final int bdayMonth = bday.get(MONTH_OF_YEAR);
		final int bdayDay = bday.get(DAY_OF_MONTH);
		
		OffsetDateTime nextCheckup = OffsetDateTime.
			of(thisYear, bdayMonth, bdayDay, 12, 0, 0, 0, ZoneOffset.UTC).
			plusDays(7);

		if (nextCheckup.isBefore(today)) {
			nextCheckup = nextCheckup.plusYears(1);
		}
		
		return nextCheckup;
	}
	
	default String getBreed() {
		return getDogData().breed;
	}
	
	default String getName() {
		return getDogData().name;
	}
	
	default OffsetDateTime getBirthDate() {
		return getDogData().birthDate;
	}
}
