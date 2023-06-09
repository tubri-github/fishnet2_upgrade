import pandas as pd
import re

df = pd.read_csv('C://work//Fishnet2//decimal_latng.csv')


def convert_dms_to_decimal(dms_str):
    try:
        # Try to parse the input as a floating-point number
        return float(dms_str)
    except ValueError:
        # If the input cannot be parsed as a floating-point number,
        # try to parse it as a DMS (degrees, minutes, seconds) string
        if dms_str == '#VALUE!' or dms_str =='Rutherford':
            return 'nan'
            # Try to parse the input as a floating-point number
        direction = dms_str[-1]
        dms = dms_str[:-1]  # Remove the direction letter

        degrees, minutes, seconds = 0, 0, 0
        numbers = re.findall(r'\d+', dms)

        # If there are clear separators for degrees, minutes, and seconds
        if numbers:
            if len(numbers) > 0:
                degrees = int(numbers[0])
            if len(numbers) > 1:
                minutes = int(numbers[1])
            if len(numbers) > 2:
                seconds = int(numbers[2])
        # If there are no clear separators for degrees, minutes, and seconds
        else:
            if len(dms) <= 2:
                degrees = int(dms)
            elif len(dms) <= 4:
                degrees = int(dms[:2])
                minutes = int(dms[2:])
            elif len(dms) <= 6:
                degrees = int(dms[:2])
                minutes = int(dms[2:4])
                seconds = int(dms[4:])
            else:
                degrees = int(dms[:3])
                minutes = int(dms[3:5])
                seconds = int(dms[5:])

        decimal_degrees = degrees + minutes / 60 + seconds / 3600

        if direction in ['S', 'W']:
            decimal_degrees *= -1

        return decimal_degrees


# Apply the function to the data columns
df['decimal_latitude'] = df['latitude'].apply(convert_dms_to_decimal)
df['decimal_longitude'] = df['longitude'].apply(convert_dms_to_decimal)

# Print the result
df.to_excel('C://work//Fishnet2//dmc2decimal.xlsx', index=False)