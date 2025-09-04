#!/usr/bin/env python3
"""Simple test script to verify database connectivity"""

import asyncio
import os
import databases

# Database configuration
POSTGRES_HOST = os.environ.get("POSTGRES_HOST", "localhost")
POSTGRES_PORT = int(os.environ.get("POSTGRES_PORT", "5432"))
POSTGRES_DB = os.environ.get("POSTGRES_DB", "postgres")
POSTGRES_USER = os.environ.get("POSTGRES_USER", "postgres")
POSTGRES_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "example")

DATABASE_URL = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"

async def test_connection():
    """Test database connection and basic operations"""
    print(f"Testing connection to: {DATABASE_URL.replace(POSTGRES_PASSWORD, '***')}")

    database = databases.Database(DATABASE_URL)

    try:
        await database.connect()
        print("✅ Connected to database successfully")

        # Test basic query
        result = await database.fetch_val("SELECT version()")
        print(f"✅ PostgreSQL version: {result}")

        # Test table creation
        await database.execute("""
            CREATE TABLE IF NOT EXISTS ping_pong_test (
                id SERIAL PRIMARY KEY,
                counter INTEGER NOT NULL DEFAULT 0,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        print("✅ Test table created successfully")

        # Test insert with named parameters
        await database.execute("INSERT INTO ping_pong_test (counter) VALUES (:counter)", {"counter": 42})
        print("✅ Test insert with named parameters successful")

        # Test select
        result = await database.fetch_val("SELECT counter FROM ping_pong_test WHERE counter = :counter", {"counter": 42})
        print(f"✅ Test select successful: {result}")

        # Test update with named parameters
        await database.execute(
            "UPDATE ping_pong_test SET counter = :new_counter WHERE counter = :old_counter",
            {"new_counter": 100, "old_counter": 42}
        )
        print("✅ Test update with named parameters successful")

        # Verify update
        result = await database.fetch_val("SELECT counter FROM ping_pong_test WHERE counter = 100")
        print(f"✅ Update verification successful: {result}")

        # Cleanup
        await database.execute("DROP TABLE ping_pong_test")
        print("✅ Test cleanup successful")

    except Exception as e:
        print(f"❌ Database test failed: {e}")
        return False
    finally:
        await database.disconnect()
        print("✅ Disconnected from database")

    return True

if __name__ == "__main__":
    success = asyncio.run(test_connection())
    if success:
        print("\n🎉 All database tests passed!")
    else:
        print("\n💥 Database tests failed!")
        exit(1)