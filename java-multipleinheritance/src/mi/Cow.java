package mi;

import static java.time.temporal.ChronoField.DAY_OF_MONTH;
import static java.time.temporal.ChronoField.HOUR_OF_DAY;
import static java.time.temporal.ChronoField.MINUTE_OF_HOUR;
import static java.time.temporal.ChronoField.MONTH_OF_YEAR;
import static java.time.temporal.ChronoField.NANO_OF_SECOND;
import static java.time.temporal.ChronoField.SECOND_OF_MINUTE;
import static java.time.temporal.ChronoField.YEAR;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

class CowData {
	String breed;
	OffsetDateTime birthDate;

	CowData(String breed, OffsetDateTime birthDate) {
		this.breed = breed;
		this.birthDate = birthDate;
	}
}

public interface Cow {
	/**
	 * The method the class has to implement to return a CowData instance, from one its own fields.
	 * 
	 * @return cow data
	 */
	CowData getCowData();
	
	/**
	 * Return the next time the cow should go to the vet for a shot,
	 * which is annually, one week before the cow's birthday.
	 * 
	 * @return date of next checkup.
	 */
	default OffsetDateTime nextCheckup() {
		final OffsetDateTime now = OffsetDateTime.now();
		
		final OffsetDateTime today = now.
			minusHours(now.get(HOUR_OF_DAY)).
			minusMinutes(now.get(MINUTE_OF_HOUR)).
			minusSeconds(now.get(SECOND_OF_MINUTE)).
			minusNanos(now.get(NANO_OF_SECOND));
		
		final OffsetDateTime bday = getCowData().birthDate;
		final int thisYear = now.get(YEAR);
		final int bdayMonth = bday.get(MONTH_OF_YEAR);
		final int bdayDay = bday.get(DAY_OF_MONTH);
		
		OffsetDateTime nextCheckup = OffsetDateTime.
			of(thisYear, bdayMonth, bdayDay, 12, 0, 0, 0, ZoneOffset.UTC).
			minusDays(7);
		
		if (nextCheckup.isBefore(today)) {
			nextCheckup = nextCheckup.plusYears(1);
		}
		
		return nextCheckup;
	}
	
	default String getBreed() {
		return getCowData().breed;
	}
	
	default OffsetDateTime getBirthDate() {
		return getCowData().birthDate;
	}
}
