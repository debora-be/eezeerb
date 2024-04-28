BEGIN;

-- Create a new temporary table with desired structure
CREATE TABLE new_check_ins (
    "id" SERIAL PRIMARY KEY,
    "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "attendee_id" INTEGER NOT NULL,
    CONSTRAINT "new_check_ins_attendee_id_fkey" FOREIGN KEY ("attendee_id") REFERENCES "attendees" ("id") ON DELETE CASCADE
);

-- Savepoint for partial rollback in case of errors
SAVEPOINT before_insert_check_ins;

-- Copy data from old table to new table
INSERT INTO new_check_ins ("attendee_id", "created_at", "id")
SELECT "attendee_id", "created_at", "id" FROM check_ins;

-- If there are no errors, drop the old table and rename the new one
DROP TABLE check_ins;
ALTER TABLE new_check_ins RENAME TO check_ins;

-- Repeat process for attendees
SAVEPOINT before_create_attendees;
CREATE TABLE new_attendees (
    "id" SERIAL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "event_id" TEXT NOT NULL,
    CONSTRAINT "new_attendees_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events" ("id") ON DELETE CASCADE
);

SAVEPOINT before_insert_attendees;
INSERT INTO new_attendees ("created_at", "email", "event_id", "id", "name")
SELECT "created_at", "email", "event_id", "id", "name" FROM attendees;

DROP TABLE attendees;
ALTER TABLE new_attendees RENAME TO attendees;

-- Create any necessary indexes
CREATE UNIQUE INDEX "check_ins_attendee_id_key" ON "check_ins"("attendee_id");
CREATE UNIQUE INDEX "attendees_event_id_email_key" ON "attendees"("event_id", "email");

-- Commit all changes
COMMIT;
