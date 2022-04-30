import React from "react"
import { BrowserRouter as Router, Route, Routes } from "react-router-dom"
import { ApolloClient, ApolloProvider, InMemoryCache } from "@apollo/client"

import { Home } from "./Home"
import { Carbon } from "./Carbon"
import { Recruiting } from "./Recruiting"

const createApolloClient = () => {
    return new ApolloClient({
        cache: new InMemoryCache(),
        uri: "https://63sahjvltfatfii2yzjuj5jrjy.appsync-api.us-west-2.amazonaws.com/graphql",
        headers: { "x-api-key": "da2-xhjn6hn7rndkjonkl27ubo4dha" },
    })
}

class App extends React.Component {
    render() {
        return (
            <ApolloProvider client={createApolloClient()}>
                <Router>
                    <Routes>
                        <Route path="/" element={<Home />} />
                        <Route path="/recruiting" element={<Recruiting />} />
                        <Route path="/carbon" element={<Carbon />} />
                    </Routes>
                </Router>
            </ApolloProvider>
        )
    }
}

export default App
