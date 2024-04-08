import React from 'react'
import { Link } from 'react-router-dom';
import "./Navbar.css";


/**
 * creates the navigation bar for the home menu
 * @returns the nav bar for home
 */
const Navbar = () => {
    return (
        <div className='header_page'>
            <div className='header'>
                <ul class="nav">
                    <li class="nav-item">
                        <Link to='/'>Overview</Link>
                    </li>
                    <li class="nav-item">
                        <Link to='/Runs'>Individual Runs</Link>
                    </li>
                    <li class="nav-item">
                        <Link to='/Data'>Data Trends</Link>
                    </li>
                </ul>
            </div>
        </div>
    )
}

export default Navbar;