import csv

def prompt_csv_path():
    return input("Enter path to CSV file: ").strip()

def find_data_section(csvfile):
    for line in csvfile:
        if line.strip() == "Data:":
            break
    return csvfile

def aggregate_registers(header, data_row):
    # Skip the first column (time)
    header = header[1:]
    data_row = data_row[1:]
    aggregated_titles = []
    aggregated_values = []

    i = 0
    while i < len(header):
        # Extract register name from header, e.g., "foo[7]~reg0" -> "foo"
        reg_name = '['.join(header[i].split('[')[0:3])
        aggregated_titles.append(reg_name)
        # Collect 8 bits for this register
        bits = data_row[i:i+8]
        # Convert bits (as strings) to integer, MSB first
        value = 0
        for bit in bits:
            value = (value << 1) | int(bit)
        aggregated_values.append(value)
        i += 8
    return aggregated_titles, aggregated_values

def main():
    csv_path = prompt_csv_path()
    with open(csv_path, newline='') as csvfile:
        # Find the "Data:" line
        lines = find_data_section(csvfile)
        reader = csv.reader(lines)
        try:
            header = next(reader)
            data_row = next(reader)
        except StopIteration:
            print("CSV does not contain enough data after 'Data:'")
            return

        titles, values = aggregate_registers(header, data_row)
        print("Aggregated column titles:", titles)
        print("Aggregated data row:", values)

if __name__ == "__main__":
    main()