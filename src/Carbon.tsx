import React from "react"
import {useQuery, gql} from "@apollo/client"

const ATMOS_C_TO_REMOVE = gql`
    query TestQuery {
        atmosphericCarbonTonsToRemove
    }
`

export const Carbon = () => {
    const {loading, data} = useQuery(ATMOS_C_TO_REMOVE)

    return (
        <div>
            <h1>Atmospheric Carbon Removal Goal</h1>
            {loading? (<p>Loading...</p>) : (
                <p>{data?.atmosphericCarbonTonsToRemove}</p>
            )}
        </div>
    )
}
