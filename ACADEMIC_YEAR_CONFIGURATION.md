# Academic Year Configuration Guide

## Current Configuration
- **Start Year**: 2024/2025
- **End Year**: 2033/2034
- **Total Years**: 10 years

## How to Change the Year Range

### Location
File: `client/components/Layout.tsx`

Look for this section (around line 70-80):

```typescript
// Generate academic year options (2024/2025 to 2033/2034)
// To add more years: Change the start year (2024) or increase the range (10 years)
const startYear = 2024; // ← Change this to start from a different year
const yearRange = 10;   // ← Change this to show more/fewer years (currently shows 10 years)

const academicYearOptions = [];
for (let i = 0; i < yearRange; i++) {
  const year = startYear + i;
  const nextYear = year + 1;
  academicYearOptions.push(`${year}/${nextYear}`);
}
```

### Examples

#### Example 1: Start from 2025 instead of 2024
```typescript
const startYear = 2025; // Now shows 2025/2026 to 2034/2035
const yearRange = 10;
```

#### Example 2: Show 20 years instead of 10
```typescript
const startYear = 2024; // Now shows 2024/2025 to 2043/2044
const yearRange = 20;
```

#### Example 3: Start from 2020 and show 15 years
```typescript
const startYear = 2020; // Now shows 2020/2021 to 2034/2035
const yearRange = 15;
```

#### Example 4: Only show 5 years
```typescript
const startYear = 2024; // Now shows 2024/2025 to 2028/2029
const yearRange = 5;
```

## What This Controls

The academic year dropdown in the header (top right) will show:
- **First option**: `startYear/startYear+1` (e.g., 2024/2025)
- **Last option**: `startYear+yearRange-1/startYear+yearRange` (e.g., 2033/2034)

## When to Change

### Change `startYear` when:
- You want to start from a different year
- You're setting up a new school that started in a different year
- You want to include historical data from earlier years

### Change `yearRange` when:
- You need more years in the dropdown (e.g., for long-term planning)
- You want fewer options to keep the dropdown shorter
- You're planning for future academic years

## Important Notes

1. **No Database Changes Needed**: This only affects the dropdown options
2. **Historical Data Preserved**: Changing this doesn't delete any existing data
3. **Immediate Effect**: Changes take effect after refreshing the browser
4. **All Schools Affected**: This is a frontend setting that affects all schools using the system

## Current Dropdown Options

With the current settings (startYear=2024, yearRange=10), the dropdown shows:
1. 2024/2025
2. 2025/2026
3. 2026/2027
4. 2027/2028
5. 2028/2029
6. 2029/2030
7. 2030/2031
8. 2031/2032
9. 2032/2033
10. 2033/2034

## Recommended Settings

### For New Schools (Starting Now)
```typescript
const startYear = 2024;
const yearRange = 10;  // Covers next 10 years
```

### For Established Schools (With Historical Data)
```typescript
const startYear = 2020;  // Include past 4 years
const yearRange = 15;    // Cover 15 years total
```

### For Long-Term Planning
```typescript
const startYear = 2024;
const yearRange = 20;  // Plan for next 20 years
```

## Testing Your Changes

1. Edit `client/components/Layout.tsx`
2. Change `startYear` and/or `yearRange`
3. Save the file
4. Refresh your browser (Ctrl+R or Cmd+R)
5. Click the academic year dropdown in the header
6. Verify the options match your expectations

---

**Need Help?** If you need to change this, just edit the two numbers in Layout.tsx and refresh your browser!
